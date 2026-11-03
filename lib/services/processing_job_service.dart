import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundsight/constants/backend_config.dart';
import 'package:soundsight/localization/localization_extension.dart';

class ProcessingJobException implements Exception {
  const ProcessingJobException(this.statusCode);
  final int statusCode;

  String message(BuildContext context) => switch (statusCode) {
    401 => context.l10n.translationSignInAgain,
    403 => context.l10n.translationVerifyEmail,
    409 => context.l10n.jobAlreadyActive,
    426 => context.l10n.jobUpdateRequired,
    429 => context.l10n.jobQueueFull,
    0 || 502 || 503 || 504 || 530 => context.l10n.backendServiceUnavailable,
    _ => context.l10n.jobSubmissionUnconfirmed,
  };
}

class ProcessingJob {
  const ProcessingJob({required this.id, required this.status});
  final String id;
  final String status;
  bool get isActive => status == 'queued' || status == 'processing';

  factory ProcessingJob.fromMap(Map<String, dynamic> data) {
    final id = data['jobId'];
    final status = data['status'];
    if (id is! String || id.isEmpty || status is! String) {
      throw const ProcessingJobException(0);
    }
    return ProcessingJob(id: id, status: status);
  }
}

class ProcessingJobService {
  ProcessingJobService({
    this._client,
    this._tokenProvider,
    this._userIdProvider,
  });
  final http.Client? _client;
  final Future<String> Function()? _tokenProvider;
  final String? Function()? _userIdProvider;
  static final _accepted = StreamController<void>.broadcast();
  static Stream<void> get accepted => _accepted.stream;
  static final Map<String, Future<ProcessingJob>> _submissions = {};
  static final Map<String, ProcessingJobException> _submissionErrors = {};
  static final Map<String, ProcessingJob> _activeJobs = {};
  static final Map<
    String,
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>
  >
  _jobSubscriptions = {};
  static final Map<String, Timer> _statusPollers = {};
  static final Set<String> _polling = {};
  static final _changes = StreamController<void>.broadcast();
  static Stream<void> get changes => _changes.stream;

  static ProcessingJob? activeJob(String ownerId, String path) =>
      _activeJobs['$ownerId:$path'];

  static ProcessingJobException? lastSubmissionError(
    String ownerId,
    String path,
  ) => _submissionErrors['$ownerId:$path'];

  static bool isBusy(String ownerId, String path) {
    final key = '$ownerId:$path';
    return _submissions.containsKey(key) || _activeJobs.containsKey(key);
  }

  static String identifier() => base64Url
      .encode(List<int>.generate(24, (_) => Random.secure().nextInt(256)))
      .replaceAll('=', '');

  Future<ProcessingJob> submit(String path) {
    final uid = _userIdProvider != null
        ? _userIdProvider()
        : FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw const ProcessingJobException(401);
    final cacheKey = '$uid:$path';
    final active = _activeJobs[cacheKey];
    if (active != null) return Future.value(active);
    return _submissions.putIfAbsent(cacheKey, () async {
      _submissionErrors.remove(cacheKey);
      _changes.add(null);
      try {
        return await _submit(path, cacheKey, uid);
      } on ProcessingJobException catch (error) {
        _submissionErrors[cacheKey] = error;
        rethrow;
      } catch (_) {
        const error = ProcessingJobException(0);
        _submissionErrors[cacheKey] = error;
        throw error;
      } finally {
        _submissions.remove(cacheKey);
        _changes.add(null);
      }
    });
  }

  Future<ProcessingJob> _submit(
    String path,
    String cacheKey,
    String owner,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final preferenceKey = 'processing-submission:$cacheKey';
    final key = preferences.getString(preferenceKey) ?? identifier();
    await preferences.setString(preferenceKey, key);
    try {
      final client = _client ?? http.Client();
      late http.Response response;
      try {
        final token = await (_tokenProvider ?? requireToken)();
        response = await BackendConfig.request(
          path,
          retryOnAddressChange: true,
          send: (uri) => client
              .post(
                uri,
                headers: {
                  'Authorization': 'Bearer $token',
                  'Idempotency-Key': key,
                  'X-SoundSight-Job-Protocol': '1',
                },
              )
              .timeout(const Duration(seconds: 30)),
        );
      } finally {
        if (_client == null) client.close();
      }
      if (response.statusCode != 202) {
        if (response.statusCode >= 400 && response.statusCode < 500) {
          await preferences.remove(preferenceKey);
        }
        throw ProcessingJobException(response.statusCode);
      }
      final job = ProcessingJob.fromMap(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      _trackAcceptedJob(cacheKey, owner, job);
      await preferences.remove(preferenceKey);
      _accepted.add(null);
      return job;
    } on ProcessingJobException {
      rethrow;
    } catch (_) {
      // Keep the key: a lost response must not create another job on Retry.
      throw const ProcessingJobException(0);
    }
  }

  static void _trackAcceptedJob(String key, String owner, ProcessingJob job) {
    if (!job.isActive) return;
    // This lock survives leaving the route, including before its item listener
    // catches up. Only this job's confirmed terminal state releases the lock.
    _activeJobs[key] = job;
    _changes.add(null);
    _jobSubscriptions.remove(key)?.cancel();
    _jobSubscriptions[key] = FirebaseFirestore.instance
        .collection('users')
        .doc(owner)
        .collection('processingJobs')
        .doc(job.id)
        .snapshots(includeMetadataChanges: true)
        .listen(
          (snapshot) {
            if (snapshot.metadata.isFromCache ||
                !snapshot.exists ||
                _activeJobs[key]?.id != job.id) {
              return;
            }
            final data = snapshot.data()!;
            if (data['ownerId'] != owner) return;
            final status = data['status'];
            if (status is String) _applyStatus(key, job.id, status);
          },
          onError: (Object _) {
            if (FirebaseAuth.instance.currentUser?.uid != owner) {
              _releaseJob(key, job.id);
            }
          },
        );
    _statusPollers.remove(key)?.cancel();
    _statusPollers[key] = Timer.periodic(const Duration(seconds: 5), (_) {
      unawaited(_pollStatus(key, owner, job.id));
    });
    unawaited(_pollStatus(key, owner, job.id));
  }

  static void _applyStatus(String key, String jobId, String status) {
    if (_activeJobs[key]?.id != jobId) return;
    if (_activeJobs[key]?.status == 'processing' && status == 'queued') return;
    if (status == 'completed' || status == 'failed' || status == 'cancelled') {
      _releaseJob(key, jobId);
    } else if ((status == 'queued' || status == 'processing') &&
        _activeJobs[key]?.status != status) {
      _activeJobs[key] = ProcessingJob(id: jobId, status: status);
      _changes.add(null);
    }
  }

  static Future<void> _pollStatus(
    String key,
    String owner,
    String jobId,
  ) async {
    if (_activeJobs[key]?.id != jobId) return;
    if (FirebaseAuth.instance.currentUser?.uid != owner) {
      _releaseJob(key, jobId);
      return;
    }
    if (!_polling.add(jobId)) return;
    final client = http.Client();
    try {
      final token = await requireToken().timeout(const Duration(seconds: 10));
      final response = await BackendConfig.request(
        '/jobs/${Uri.encodeComponent(jobId)}',
        retryOnAddressChange: true,
        send: (uri) => client
            .get(uri, headers: {'Authorization': 'Bearer $token'})
            .timeout(const Duration(seconds: 10)),
      );
      if (response.statusCode != 200) return;
      final job = ProcessingJob.fromMap(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      if (job.id == jobId) _applyStatus(key, jobId, job.status);
    } catch (_) {
      // A failed status check must never unlock an accepted conversion.
    } finally {
      client.close();
      _polling.remove(jobId);
    }
  }

  static void _releaseJob(String key, String jobId) {
    if (_activeJobs[key]?.id != jobId) return;
    _activeJobs.remove(key);
    _statusPollers.remove(key)?.cancel();
    _jobSubscriptions.remove(key)?.cancel();
    _changes.add(null);
  }

  Future<ProcessingJob> cancel(String jobId) async {
    try {
      final token = await requireToken();
      final response = await BackendConfig.request(
        '/jobs/${Uri.encodeComponent(jobId)}/cancel',
        retryOnAddressChange: true,
        send: (uri) => http
            .post(uri, headers: {'Authorization': 'Bearer $token'})
            .timeout(const Duration(seconds: 30)),
      );
      if (response.statusCode != 200) {
        throw ProcessingJobException(response.statusCode);
      }
      return ProcessingJob.fromMap(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } on ProcessingJobException {
      rethrow;
    } catch (_) {
      throw const ProcessingJobException(0);
    }
  }

  static Future<String> requireToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw const ProcessingJobException(401);
    final token = await user.getIdToken();
    if (token == null) throw const ProcessingJobException(401);
    return token;
  }
}

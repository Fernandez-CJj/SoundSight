"""Contain every rendering descendant, including on abrupt supervisor exit."""
import ctypes
import os
import signal
import subprocess


class ProcessTree:
    def __init__(self, command, output, cwd, env=None, runner_gate=True):
        self.handle = None
        if os.name == "nt":
            from ctypes import wintypes as w

            class Basic(ctypes.Structure):
                _fields_ = [("PerProcessUserTimeLimit", ctypes.c_int64),
                            ("PerJobUserTimeLimit", ctypes.c_int64), ("LimitFlags", w.DWORD),
                            ("MinimumWorkingSetSize", ctypes.c_size_t), ("MaximumWorkingSetSize", ctypes.c_size_t),
                            ("ActiveProcessLimit", w.DWORD), ("Affinity", ctypes.c_size_t),
                            ("PriorityClass", w.DWORD), ("SchedulingClass", w.DWORD)]

            class IO(ctypes.Structure):
                _fields_ = [(name, ctypes.c_uint64) for name in (
                    "ReadOperationCount", "WriteOperationCount", "OtherOperationCount",
                    "ReadTransferCount", "WriteTransferCount", "OtherTransferCount")]

            class Extended(ctypes.Structure):
                _fields_ = [("BasicLimitInformation", Basic), ("IoInfo", IO),
                            ("ProcessMemoryLimit", ctypes.c_size_t), ("JobMemoryLimit", ctypes.c_size_t),
                            ("PeakProcessMemoryUsed", ctypes.c_size_t), ("PeakJobMemoryUsed", ctypes.c_size_t)]

            self.kernel = ctypes.WinDLL("kernel32", use_last_error=True)
            self.kernel.CreateJobObjectW.argtypes = [ctypes.c_void_p, w.LPCWSTR]
            self.kernel.CreateJobObjectW.restype = w.HANDLE
            self.kernel.SetInformationJobObject.argtypes = [w.HANDLE, ctypes.c_int, ctypes.c_void_p, w.DWORD]
            self.kernel.AssignProcessToJobObject.argtypes = [w.HANDLE, w.HANDLE]
            self.kernel.CloseHandle.argtypes = [w.HANDLE]
            self.handle = self.kernel.CreateJobObjectW(None, None)
            limits = Extended()
            limits.BasicLimitInformation.LimitFlags = 0x2000  # KILL_ON_JOB_CLOSE
            if not self.handle or not self.kernel.SetInformationJobObject(self.handle, 9, ctypes.byref(limits), ctypes.sizeof(limits)):
                self.close()
                raise ctypes.WinError(ctypes.get_last_error())
        try:
            self.process = subprocess.Popen(command, cwd=cwd, env=env, stdin=subprocess.PIPE, stdout=output,
                                            stderr=subprocess.STDOUT, start_new_session=os.name != "nt",
                                            creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
            if self.handle and not self.kernel.AssignProcessToJobObject(self.handle, int(self.process._handle)):
                self.process.kill()
                self.process.wait()
                raise ctypes.WinError(ctypes.get_last_error())
            # The runner cannot start tools until it belongs to the Job Object.
            if runner_gate:
                self.process.stdin.write(b"run\n")
            self.process.stdin.close()
        except BaseException:
            self.close()
            raise

    def close(self):
        if self.handle:
            self.kernel.CloseHandle(self.handle)
            self.handle = None
        process = getattr(self, "process", None)
        if process and process.poll() is None:
            if os.name != "nt":
                os.killpg(process.pid, signal.SIGKILL)
            else:
                process.kill()
            process.wait(timeout=15)


class WorkerLock:
    def __init__(self, path):
        self.file = open(path, "a+b")
        if self.file.tell() == 0:
            self.file.write(b"0")
            self.file.flush()
        self.file.seek(0)
        try:
            if os.name == "nt":
                import msvcrt
                msvcrt.locking(self.file.fileno(), msvcrt.LK_NBLCK, 1)
            else:
                import fcntl
                fcntl.flock(self.file.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            self.file.close()
            raise RuntimeError("A SoundSight worker already owns this queue.") from None

    def close(self):
        self.file.close()

class FeatureTourHint {
  const FeatureTourHint(this.id, this.title, this.filipinoTitle, this.body, this.filipinoBody);
  final String id;
  final String title;
  final String filipinoTitle;
  final String body;
  final String filipinoBody;
}

// Copy is kept beside the target definitions in both supported languages.
const featureTourCatalog = <String, List<FeatureTourHint>>{
  'music_sheet_viewer': [
    FeatureTourHint('preview', 'Your music pages', 'Mga pahina ng musika', 'Here are your music pages. You can look at them before you play.', 'Narito ang mga pahina ng musika. Tingnan muna bago tumugtog.'),
    FeatureTourHint('expand', 'Make the page bigger', 'Palakihin ang pahina', 'Tap this to see a bigger page. Swipe up to see more pages, then close it to come back.', 'I-tap ito para lumaki ang pahina. Mag-swipe pataas para sa iba pang pahina. Isara para bumalik.'),
    FeatureTourHint('audio', 'Listen to the song', 'Pakinggan ang kanta', 'Tap Play to listen. Tap Stop or Pause when you want a break.', 'I-tap ang Play para makinig. I-tap ang Stop o Pause para huminto muna.'),
    FeatureTourHint('process', 'Is your song ready?', 'Handa na ba ang kanta?', 'This tells you if the app is still getting your song ready. Wait until it is done before playing.', 'Sinasabi rito kung inihahanda pa ang kanta. Hintaying matapos bago tumugtog.'),
    FeatureTourHint('practice', 'Choose how to play', 'Pumili ng paraan ng pagtugtog', 'Tap Play to pick how you want to learn this song. You can read notes or follow moving notes.', 'I-tap ang Play para pumili kung paano aaralin ang kanta. Maaari kang magbasa o sumunod sa gumagalaw na nota.'),
  ],
  'music_library': [
    FeatureTourHint('search', 'Find a song', 'Maghanap ng kanta', 'Type a song name here. Clear the words to see all the songs again.', 'I-type dito ang pangalan ng kanta. Burahin ang mga salita para makita muli ang lahat.'),
    FeatureTourHint('results', 'Look inside a song', 'Tingnan ang isang kanta', 'These are the songs you can choose. Tap Next to open one and see its music pages.', 'Ito ang mga kantang maaari mong piliin. I-tap ang Susunod para buksan ang isa at makita ang mga pahina nito.'),
  ],
  'library_piece': [
    FeatureTourHint('preview', 'Meet this song', 'Kilalanin ang kanta', 'Look at the song name and its music pages. Take your time before you play.', 'Tingnan ang pangalan at mga pahina ng kanta. Maghanda muna bago tumugtog.'),
    FeatureTourHint('practice', 'Play and learn', 'Tumugtog at matuto', 'Tap Play when you are ready. Choose the way you want to learn this song.', 'I-tap ang Play kapag handa ka na. Pumili kung paano mo gustong aralin ang kanta.'),
  ],
  'my_compositions': [
    FeatureTourHint('create', 'Make your own song', 'Gumawa ng sariling kanta', 'Tap the plus sign to make a song. You can add notes with the piano or record yourself playing.', 'I-tap ang plus para gumawa ng kanta. Maglagay ng nota gamit ang piano o i-record ang iyong pagtugtog.'),
    FeatureTourHint('list', 'Songs you made', 'Mga ginawa mong kanta', 'Your songs live here. You can open them to listen, make changes, or share them.', 'Narito ang iyong mga kanta. Buksan para makinig, magbago ng nota, o magbahagi.'),
    FeatureTourHint('card_info', 'Open your song', 'Buksan ang iyong kanta', 'Tap Next to look inside this song. You can see its music pages and learn how to change its notes.', 'I-tap ang Susunod para tingnan ang kanta. Makikita mo ang mga pahina at kung paano baguhin ang mga nota.'),
    FeatureTourHint('empty', 'Make your first song', 'Gumawa ng unang kanta', 'No songs yet! Tap Next to name your first song and choose how to make it. Choose Start when you are ready.', 'Wala pang kanta! I-tap ang Susunod para pangalanan ito at pumili ng paraan. Piliin ang Start kapag handa ka na.'),
  ],
  'manual_composition': [
    FeatureTourHint('midi', 'Use your piano', 'Gamitin ang iyong piano', 'You can connect a piano to your phone and add notes by pressing its keys.', 'Maaari mong ikonekta ang piano sa telepono at magdagdag ng nota sa pagpindot ng mga key.'),
    FeatureTourHint('settings', 'Name and speed', 'Pangalan at bilis', 'Give your song a name and choose how fast it should go. You can change its other music choices here too.', 'Pangalanan ang kanta at piliin ang bilis. Dito rin mababago ang iba pang pagpipilian sa musika.'),
    FeatureTourHint('duration', 'Long or short notes', 'Mahaba o maikling nota', 'Choose how long a note should last. Then press a piano key to add it.', 'Piliin kung gaano katagal ang nota. Pindutin ang key ng piano para idagdag ito.'),
    FeatureTourHint('timeline', 'Your notes go here', 'Dito mapupunta ang mga nota', 'Tap a note to choose it. Use the buttons nearby to move, change, or remove notes.', 'I-tap ang nota para piliin ito. Gamitin ang mga button sa tabi para ilipat, baguhin, o alisin ito.'),
    FeatureTourHint('note_entry', 'Add a note', 'Magdagdag ng nota', 'Tap a piano key to add a note to your song. This guide will not add any notes for you.', 'I-tap ang key para magdagdag ng nota. Walang idaragdag na nota ang gabay na ito.'),
    FeatureTourHint('playback', 'Hear your song', 'Pakinggan ang iyong kanta', 'Tap Play to hear what you made. Stop the song before you change its notes.', 'I-tap ang Play para marinig ang ginawa mo. Ihinto muna bago baguhin ang mga nota.'),
    FeatureTourHint('save', 'Keep your song', 'Itago ang iyong kanta', 'Tap Save when you want to keep your work. Wait for it to finish before leaving.', 'I-tap ang Save para maitago ang ginawa mo. Hintaying matapos bago umalis.'),
  ],
  'recording_composition': [
    FeatureTourHint('midi', 'Connect your piano', 'Ikonekta ang piano', 'Connect your piano first. Let the app use the camera if your phone asks.', 'Ikonekta muna ang piano. Payagan ang camera kapag nagtanong ang telepono.'),
    FeatureTourHint('record', 'Record your song', 'I-record ang iyong kanta', 'Tap Start when you are ready to play. Tap Stop when you finish, then choose how to keep your song.', 'I-tap ang Start kapag handa ka nang tumugtog. I-tap ang Stop kapag tapos na, saka piliin kung paano itatago ang kanta.'),
    FeatureTourHint('camera', 'Pick a camera', 'Pumili ng camera', 'Use this button to switch cameras before you start. This guide will not record you.', 'Gamitin ito para lumipat ng camera bago magsimula. Hindi ka ire-record ng gabay.'),
  ],
  'composition_details': [
    FeatureTourHint('overview', 'About your song', 'Tungkol sa iyong kanta', 'Here is your song name and its music choices. Check them before you play.', 'Narito ang pangalan at mga pagpipilian ng kanta. Tingnan muna bago tumugtog.'),
    FeatureTourHint('playback', 'Listen to your song', 'Pakinggan ang iyong kanta', 'Tap Play to listen. Stop the song when you want to make changes.', 'I-tap ang Play para makinig. Ihinto kapag gusto mong baguhin ang kanta.'),
    FeatureTourHint('preview', 'Your music pages', 'Mga pahina ng iyong kanta', 'See the music pages the app made for your song. Make a page bigger to look at it closely.', 'Tingnan ang mga pahina ng kantang ginawa ng app. Palakihin para makita nang mas malinaw.'),
    FeatureTourHint('actions', 'What comes next?', 'Ano ang susunod?', 'You can play or share your song here. If you see Next, tap it to learn how to change the notes.', 'Maaari mong tugtugin o ibahagi ang kanta. Kung may Susunod, i-tap ito para matutong baguhin ang mga nota.'),
  ],
  'published_compositions': [
    FeatureTourHint('sort', 'Pick what comes first', 'Piliin ang mauuna', 'Your own shared songs come first. Choose Most liked to see popular songs, or Newest to see recent ones.', 'Nauuna ang sarili mong ibinahaging kanta. Piliin ang Pinakamaraming like o Pinakabago para sa ibang kanta.'),
    FeatureTourHint('card_info', 'Songs from other people', 'Mga kanta ng ibang tao', 'Tap a song to see who made it and to look at its music pages.', 'I-tap ang kanta para malaman kung sino ang gumawa at makita ang mga pahina nito.'),
    FeatureTourHint('social', 'Like, talk, and save', 'Mag-like, mag-usap, at mag-save', 'Tap the heart if you like a song. Leave a kind message, or save the song to find it later.', 'I-tap ang puso kung gusto mo ang kanta. Mag-iwan ng mabait na mensahe o i-save para mahanap muli.'),
    FeatureTourHint('play', 'Listen or look inside', 'Makinig o tumingin sa loob', 'Tap Play to listen. Tap Next to open this song and see its music pages.', 'I-tap ang Play para makinig. I-tap ang Susunod para buksan ang kanta at makita ang mga pahina nito.'),
    FeatureTourHint('empty', 'Shared songs go here', 'Dito ang mga ibinahaging kanta', 'There are no shared songs to show yet. You can share one of your own songs when it is ready.', 'Wala pang maipakitang ibinahaging kanta. Maaari mong ibahagi ang sarili mong kanta kapag handa na.'),
  ],
  'published_details': [
    FeatureTourHint('identity', 'Who made this song?', 'Sino ang gumawa ng kanta?', 'See the song name, who made it, and when it was shared.', 'Tingnan ang pangalan ng kanta, kung sino ang gumawa, at kailan ito ibinahagi.'),
    FeatureTourHint('details', 'More about the song', 'Iba pa tungkol sa kanta', 'Look here to learn how fast the song goes and how much music it has.', 'Tingnan dito kung gaano kabilis ang kanta at gaano ito kahaba.'),
    FeatureTourHint('social', 'Keep a song you like', 'Itago ang kantang gusto mo', 'Tap the bookmark to save this song. You can also tap the heart or leave a kind message here.', 'I-tap ang bookmark para i-save ang kanta. Maaari ring i-tap ang puso o mag-iwan ng mabait na mensahe.'),
    FeatureTourHint('preview', 'See all the pages', 'Tingnan ang lahat ng pahina', 'Tap this to make the music page bigger. Swipe up to see the next page, then close it to come back.', 'I-tap ito para palakihin ang pahina. Mag-swipe pataas para sa susunod na pahina, saka isara para bumalik.'),
    FeatureTourHint('practice', 'Try playing it', 'Subukang tugtugin', 'Tap Play and choose how you want to learn this song.', 'I-tap ang Play at pumili kung paano mo gustong aralin ang kanta.'),
  ],
  'saved_compositions': [
    FeatureTourHint('list', 'Songs you kept', 'Mga itinago mong kanta', 'The songs you save will be here, ready for you to find again.', 'Narito ang mga na-save mong kanta para madali mong mahanap muli.'),
    FeatureTourHint('card_info', 'Your saved song', 'Ang na-save mong kanta', 'You can open this song to see its pages and learn to play it.', 'Maaari mong buksan ang kanta para makita ang mga pahina at matutong tumugtog.'),
    FeatureTourHint('social', 'Keep or remove a song', 'Itago o alisin ang kanta', 'Tap the bookmark if you want to remove a song from this list. The app will ask you first.', 'I-tap ang bookmark para alisin ang kanta sa listahan. Magtatanong muna ang app.'),
    FeatureTourHint('play', 'Listen or look inside', 'Makinig o tumingin sa loob', 'Tap Play to listen. Tap Next to look inside this saved song.', 'I-tap ang Play para makinig. I-tap ang Susunod para tingnan ang na-save na kanta.'),
    FeatureTourHint('empty', 'Save a favorite song', 'Mag-save ng paboritong kanta', 'Find a song in Published Compositions and tap its bookmark. It will show up here.', 'Humanap ng kanta sa Published Compositions at i-tap ang bookmark. Lalabas ito rito.'),
  ],
  'lessons': [
    FeatureTourHint('menu', 'Open the side menu', 'Buksan ang menu sa gilid', 'Tap the three lines to open the menu. Choose Help if you want to watch this whole guide again.', 'I-tap ang tatlong guhit para buksan ang menu. Piliin ang Tulong para makita muli ang buong gabay.'),
    FeatureTourHint('progress', 'See how far you have come', 'Tingnan ang iyong narating', 'This shows the lessons you have finished. Keep going, one lesson at a time!', 'Ipinapakita nito ang mga natapos mong aralin. Magpatuloy nang paisa-isang aralin!'),
    FeatureTourHint('stages', 'Choose a lesson', 'Pumili ng aralin', 'Tap a lesson to see what you will learn. Choose Start when you are ready.', 'I-tap ang aralin para makita ang matututuhan mo. Piliin ang Start kapag handa ka na.'),
  ],
  'assessment': [
    FeatureTourHint('status', 'Find your starting place', 'Hanapin ang iyong simula', 'Answer a few questions, read some notes, and play your piano. This helps us pick a good place for you to start.', 'Sumagot ng ilang tanong, magbasa ng nota, at tumugtog. Matutulungan ka nitong malaman kung saan magsisimula.'),
    FeatureTourHint('start', 'Start when you are ready', 'Magsimula kapag handa', 'Read the rules first. The clock starts when you begin. This guide will not start or answer the quiz for you.', 'Basahin muna ang panuto. Magsisimula ang oras kapag nagsimula ka. Hindi magsisimula o sasagot ang gabay para sa iyo.'),
  ],
  'ar_setup': [
    FeatureTourHint('create', 'Help the camera find your piano', 'Ipakita sa camera ang piano', 'Let the camera see your whole keyboard. Keep your phone steady while the app finds the keys.', 'Ipakita sa camera ang buong keyboard. Panatilihing hindi gumagalaw ang telepono habang hinahanap ang mga key.'),
    FeatureTourHint('list', 'Pick your saved piano', 'Piliin ang na-save na piano', 'Choose a piano you set up before. Set it up again if you move the phone or piano.', 'Piliin ang pianong naihanda mo na. Ihanda itong muli kapag nailipat ang telepono o piano.'),
    FeatureTourHint('empty', 'Set up your first piano', 'Ihanda ang unang piano', 'Tap New Piano Setup to help the app find your keys. Follow the words on the screen.', 'I-tap ang New Piano Setup para makita ng app ang mga key. Sundan ang mga nakasulat sa screen.'),
  ],
  'practice_results': [
    FeatureTourHint('filters', 'Find a past game', 'Hanapin ang dating pagtugtog', 'Use these choices to find the song or game you want to look at again.', 'Gamitin ang mga pagpipilian para mahanap ang kantang gusto mong tingnan muli.'),
    FeatureTourHint('card_info', 'See how you did', 'Tingnan ang iyong nagawa', 'Tap Next to open this result. You can see what went well and what to try again.', 'I-tap ang Susunod para buksan ang resulta. Makikita ang nagawa mong mabuti at ang maaari mong ulitin.'),
    FeatureTourHint('empty', 'Your results go here', 'Dito ang mga resulta mo', 'Finish a game that saves results. Come back here to see how you did.', 'Tapusin ang larong nagse-save ng resulta. Bumalik dito para makita ang iyong nagawa.'),
  ],
  'practice_result_details': [
    FeatureTourHint('summary', 'How did it go?', 'Kumusta ang pagtugtog?', 'See your song, score, and the game you played. You can compare this with your older results.', 'Tingnan ang kanta, puntos, at larong nilaro mo. Maaari mo itong ihambing sa mga dating resulta.'),
    FeatureTourHint('breakdown', 'Take a closer look', 'Tingnan nang mas mabuti', 'See which notes were right and which need more practice. A little practice helps you get better!', 'Tingnan kung aling mga nota ang tama at alin ang kailangang ulitin. Makakatulong ang kaunting pagsasanay!'),
    FeatureTourHint('suggestions', 'What can I try next?', 'Ano ang susubukan ko?', 'Read these tips. Try the tricky notes slowly, then play the song again when you feel ready.', 'Basahin ang mga tip. Dahan-dahang ulitin ang mahihirap na nota, saka tugtugin muli kapag handa na.'),
  ],
  'profile': [
    FeatureTourHint('edit', 'Change your picture or name', 'Baguhin ang larawan o pangalan', 'Tap Edit to choose a picture or change your name. Save when you like it.', 'I-tap ang Edit para pumili ng larawan o baguhin ang pangalan. I-save kapag gusto mo na.'),
    FeatureTourHint('identity', 'This is you!', 'Ikaw ito!', 'Your name and picture live here.', 'Narito ang pangalan at larawan mo.'),
    FeatureTourHint('progress', 'See your progress', 'Tingnan ang pag-usad mo', 'See what you have learned and how much you have practiced.', 'Tingnan ang mga natutuhan mo at ang dami ng iyong pagsasanay.'),
    FeatureTourHint('achievements', 'Look at your badges', 'Tingnan ang mga badge mo', 'You earn badges as you learn and play. Keep practicing to earn more!', 'Makakakuha ka ng mga badge habang natututo at tumutugtog. Magpatuloy para makakuha pa!'),
    FeatureTourHint('assessment', 'Your starting level', 'Ang iyong panimulang antas', 'See your quiz result here, or open the quiz when you are ready.', 'Tingnan dito ang resulta ng pagsusulit o buksan ito kapag handa ka na.'),
    FeatureTourHint('preferences', 'Make it yours', 'Gawing para sa iyo', 'Choose your language and light or dark colors. You can watch this guide again from the side menu.', 'Piliin ang wika at maliwanag o madilim na kulay. Maaari mong ulitin ang gabay mula sa menu sa gilid.'),
  ],
  'assessment_instructions': [
    FeatureTourHint('instructions', 'Read this first', 'Basahin muna ito', 'Read what you need to do before you start. If your quiz has started, its clock keeps going while this guide is open.', 'Basahin muna ang gagawin. Kung nagsimula na ang pagsusulit, tuloy ang oras habang bukas ang gabay.'),
    FeatureTourHint('timer', 'Watch the time', 'Bantayan ang oras', 'This shows how much time is left. The clock does not stop while you read this guide.', 'Ito ang natitirang oras. Hindi humihinto ang oras habang binabasa ang gabay.'),
    FeatureTourHint('continue', 'Ready to go?', 'Handa ka na ba?', 'Tap Continue after you read the words. The app waits for you to choose.', 'I-tap ang Continue matapos basahin ang mga salita. Hihintayin ng app ang iyong pagpili.'),
  ],
  'assessment_questions': [
    FeatureTourHint('questions', 'Tell us about you', 'Ikuwento ang tungkol sa iyo', 'Choose the answer that sounds most like you. If your quiz has started, the clock keeps going.', 'Piliin ang sagot na pinakatugma sa iyo. Kung nagsimula na ang pagsusulit, tuloy ang oras.'),
    FeatureTourHint('continue', 'Check your answers', 'Tingnan ang mga sagot', 'Answer each question, then tap Continue. This guide will not choose any answers.', 'Sagutin ang bawat tanong, saka i-tap ang Continue. Hindi pipili ng sagot ang gabay.'),
  ],
  'assessment_notation': [
    FeatureTourHint('notation', 'Look at the notes', 'Tingnan ang mga nota', 'Read the question and look at the notes. Remember to watch the time.', 'Basahin ang tanong at tingnan ang mga nota. Huwag kalimutang bantayan ang oras.'),
    FeatureTourHint('answer', 'Pick your answer', 'Piliin ang sagot', 'Tap the answer you think is right. You can check your answers before you send them.', 'I-tap ang sagot na sa tingin mo ay tama. Maaari mong tingnan muli bago isumite.'),
    FeatureTourHint('continue', 'Check, then continue', 'Tingnan, saka magpatuloy', 'Check your answer. Tap Next for another question, or finish when you reach the last one.', 'Tingnan ang sagot. I-tap ang Next para sa susunod na tanong o tapusin sa huli.'),
  ],
  'assessment_piano': [
    FeatureTourHint('midi', 'Connect your piano', 'Ikonekta ang piano', 'Connect your piano to your phone. Wait until the app says it is ready.', 'Ikonekta ang piano sa telepono. Hintaying sabihin ng app na handa na.'),
    FeatureTourHint('instructions', 'What should I play?', 'Ano ang tutugtugin ko?', 'Look at which notes to play and when to play them. The quiz clock keeps going.', 'Tingnan kung anong mga nota at kailan tutugtugin. Tuloy ang oras ng pagsusulit.'),
    FeatureTourHint('continue', 'Your turn to play', 'Ikaw naman ang tutugtog', 'Tap Start when you are ready. Follow the notes and keep going.', 'I-tap ang Start kapag handa ka na. Sundan ang mga nota at magpatuloy.'),
  ],
  'assessment_results': [
    FeatureTourHint('summary', 'Your starting place', 'Ang iyong simula', 'Here is a good place for you to start learning. Some beginners will not have a piano score yet.', 'Ito ang magandang simula para sa pag-aaral mo. Maaaring wala pang puntos sa piano ang ilang baguhan.'),
    FeatureTourHint('sections', 'Look at your answers', 'Tingnan ang mga sagot mo', 'See your answers and what you played. This can help you choose what to practice next.', 'Tingnan ang mga sagot at tinugtog mo. Makakatulong ito para piliin ang susunod na pagsasanay.'),
  ],
  'lesson_content': [
    FeatureTourHint('video', 'Watch and learn', 'Manood at matuto', 'Tap Play to watch the lesson. You can pause or watch a part again whenever you want.', 'I-tap ang Play para manood ng aralin. Maaari kang huminto o ulitin ang bahagi kung gusto mo.'),
  ],
};

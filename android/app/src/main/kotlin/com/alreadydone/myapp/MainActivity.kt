package com.alreadydone.myapp

import com.ryanheise.audioservice.AudioServiceFragmentActivity

// AudioServiceFragmentActivity extends FlutterFragmentActivity, so plugins that
// require a FragmentActivity keep working while audio_service can bind playback
// to this activity.
class MainActivity : AudioServiceFragmentActivity() {
}

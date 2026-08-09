# demo.tape — the recording script for assets/demo.gif
#
# The GIF in the README is a real run, not a mockup: this drives the plugin's own
# bin/codex-imagegen against a live Codex session, so recording it costs a real image
# turn on your ChatGPT plan. Re-record with:
#
#   brew install vhs
#   vhs assets/demo.tape
#
# That writes assets/demo-raw.gif in real time (generation takes 1-2 minutes, which is
# unwatchable as a loop). assets/README.md has the ffmpeg command that speeds it up into
# the committed demo.gif.

Output assets/demo-raw.gif

Set Shell "bash"
Set FontSize 20
Set Width 1300
Set Height 560
Set Padding 30
Set TypingSpeed 45ms
Set Framerate 6
Set Theme "Catppuccin Mocha"

# Setup, not part of the demo: put the plugin's bin on PATH and work in /tmp so the
# repo's committed assets aren't clobbered by a re-record.
Hide
Type "export PATH=/Users/sateezgupta/Downloads/codex-bridge/bin:$PATH && cd /tmp && rm -f demo-rocket.png && clear"
Enter
Show

Sleep 1s
Type "# Claude Code can't generate images. Codex can. This is the bridge."
Enter
Sleep 1500ms

Type `codex-imagegen "flat vector paper rocket icon, terracotta #D97757 on warm off-white #FAF9F5, 2px darker outline, no text" demo-rocket.png --size 1024x1024`
Enter

# Real generation against gpt-image-2 on a ChatGPT plan. The wrapper prints the absolute
# path it actually wrote — "/tmp/" only ever appears in that output, never in the line
# typed above, so this waits for completion rather than matching its own echo.
Wait+Screen@6m /\/tmp\/demo-rocket\.png/

Sleep 2500ms
Type "file demo-rocket.png"
Enter
Sleep 3s

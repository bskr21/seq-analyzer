// Sequencer Analyzer - progress bar ([jsui]). Send a number 0..100.
mgraphics.init();
mgraphics.relative_coords = 0;
mgraphics.autofill = 0;
var pct = 0;

function msg_float(v) { pct = Math.max(0, Math.min(100, v)); mgraphics.redraw(); }
function msg_int(v) { msg_float(v); }

function paint() {
  var w = mgraphics.size[0], h = mgraphics.size[1], r = h / 2;
  mgraphics.set_source_rgba(0.16, 0.16, 0.16, 1.0);           // track
  mgraphics.rectangle_rounded(0, 0, w, h, r, r);
  mgraphics.fill();
  if (pct > 0) {
    mgraphics.set_source_rgba(1.0, 0.71, 0.2, 1.0);           // fill
    mgraphics.rectangle_rounded(0, 0, Math.max(h, w * pct / 100), h, r, r);
    mgraphics.fill();
  }
}

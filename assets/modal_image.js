// Opens any image with class "zoomable" in a full-screen popup.
// Uses the image's data-full attribute when present (gallery thumbnails), otherwise its src.
(function () {
  var modal = document.getElementById('imageModal');
  var modalImg = document.getElementById('modalImage');
  var captionText = document.getElementById('caption');

  function close() {
    modal.style.display = 'none';
    modalImg.src = '';
  }

  document.querySelectorAll('img.zoomable').forEach(function (img) {
    img.addEventListener('click', function () {
      modalImg.src = img.dataset.full || img.src;
      captionText.textContent = img.alt;
      modal.style.display = 'block';
    });
  });

  // Close on the X, on a click outside the image, or with Escape.
  modal.addEventListener('click', function (evt) {
    if (evt.target !== modalImg) close();
  });
  document.addEventListener('keydown', function (evt) {
    if (evt.key === 'Escape') close();
  });
})();

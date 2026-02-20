(function() {
  'use strict';

  var tooltip = document.getElementById('annotation-tooltip');
  if (!tooltip) return;

  var tooltipContent = tooltip.querySelector('.tooltip-content');
  var annotations = document.querySelectorAll('.annotated');
  var isTouchDevice = window.matchMedia('(hover: none)').matches;
  var currentAnnotation = null;

  function showTooltip(annotation) {
    var match = annotation.dataset.match;
    if (!match) return;

    currentAnnotation = annotation;
    tooltipContent.textContent = match;

    positionTooltip(annotation);
    tooltip.classList.add('visible');
  }

  function hideTooltip() {
    tooltip.classList.remove('visible');
    currentAnnotation = null;
  }

  function positionTooltip(annotation) {
    var rect = annotation.getBoundingClientRect();
    var tooltipRect = tooltip.getBoundingClientRect();
    var viewportHeight = window.innerHeight;
    var spaceAbove = rect.top;
    var spaceBelow = viewportHeight - rect.bottom;

    var showAbove = spaceAbove > tooltipRect.height + 10 && spaceBelow < tooltipRect.height + 10;

    if (showAbove) {
      tooltip.classList.add('above');
      tooltip.classList.remove('below');
      tooltip.style.top = (rect.top - tooltipRect.height - 10) + 'px';
    } else {
      tooltip.classList.add('below');
      tooltip.classList.remove('above');
      tooltip.style.top = (rect.bottom + 10) + 'px';
    }

    var left = rect.left + (rect.width / 2) - (tooltipRect.width / 2);
    var maxLeft = window.innerWidth - tooltipRect.width - 10;
    tooltip.style.left = Math.max(10, Math.min(left, maxLeft)) + 'px';
  }

  annotations.forEach(function(annotation) {
    annotation.setAttribute('tabindex', '0');

    if (isTouchDevice) {
      annotation.addEventListener('click', function(e) {
        e.preventDefault();
        e.stopPropagation();
        if (currentAnnotation === annotation) {
          hideTooltip();
        } else {
          showTooltip(annotation);
        }
      });
    } else {
      annotation.addEventListener('mouseenter', function() {
        showTooltip(annotation);
      });

      annotation.addEventListener('mouseleave', function() {
        hideTooltip();
      });
    }

    annotation.addEventListener('keydown', function(e) {
      if (e.key === 'Enter') {
        e.preventDefault();
        showTooltip(annotation);
      } else if (e.key === 'Escape') {
        e.preventDefault();
        hideTooltip();
      }
    });
  });

  if (isTouchDevice) {
    document.addEventListener('click', function(e) {
      if (!tooltip.contains(e.target) && !e.target.classList.contains('annotated')) {
        hideTooltip();
      }
    });
  }
})();

(function() {
  'use strict';

  var carousel = document.querySelector('#recommendations .carousel');
  var navButtons = document.querySelectorAll('#recommendations .btn-circle');
  if (!carousel || navButtons.length === 0) return;

  navButtons.forEach(function(btn) {
    btn.addEventListener('click', function(e) {
      e.preventDefault();

      var targetId = btn.getAttribute('href').slice(1);
      var targetItem = document.getElementById(targetId);
      if (targetItem) {
        carousel.scrollTo({ left: targetItem.offsetLeft, behavior: 'smooth' });
      }

      navButtons.forEach(function(b) {
        b.classList.remove('btn-primary');
        b.classList.add('btn-ghost');
      });
      btn.classList.remove('btn-ghost');
      btn.classList.add('btn-primary');
    });
  });
})();

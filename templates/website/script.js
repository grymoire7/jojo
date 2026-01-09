  (function() {
    'use strict';

    const tooltip = document.getElementById('annotation-tooltip');
    const tooltipContent = tooltip.querySelector('.tooltip-content');
    const annotations = document.querySelectorAll('.annotated');
    const isTouchDevice = window.matchMedia('(hover: none)').matches;
    let currentAnnotation = null;

    // Show tooltip
    function showTooltip(annotation) {
      const match = annotation.dataset.match;
      if (!match) return;

      currentAnnotation = annotation;
      tooltipContent.textContent = match;

      // Position tooltip
      positionTooltip(annotation);

      // Show with animation
      tooltip.classList.add('visible');
    }

    // Hide tooltip
    function hideTooltip() {
      tooltip.classList.remove('visible');
      currentAnnotation = null;
    }

    // Position tooltip above or below annotation
    function positionTooltip(annotation) {
      const rect = annotation.getBoundingClientRect();
      const tooltipRect = tooltip.getBoundingClientRect();
      const viewportHeight = window.innerHeight;
      const spaceAbove = rect.top;
      const spaceBelow = viewportHeight - rect.bottom;

      // Decide position: above or below
      const showAbove = spaceAbove > tooltipRect.height + 10 && spaceBelow < tooltipRect.height + 10;

      if (showAbove) {
        tooltip.classList.add('above');
        tooltip.classList.remove('below');
        tooltip.style.top = (window.scrollY + rect.top - tooltipRect.height - 10) + 'px';
      } else {
        tooltip.classList.add('below');
        tooltip.classList.remove('above');
        tooltip.style.top = (window.scrollY + rect.bottom + 10) + 'px';
      }

      // Center horizontally
      const left = rect.left + (rect.width / 2) - (tooltipRect.width / 2);
      const maxLeft = window.innerWidth - tooltipRect.width - 10;
      tooltip.style.left = Math.max(10, Math.min(left, maxLeft)) + 'px';
    }

    // Add event listeners to each annotation
    annotations.forEach(function(annotation) {
      // Make focusable for keyboard navigation
      annotation.setAttribute('tabindex', '0');

      if (isTouchDevice) {
        // Touch: tap to show, tap outside to hide
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
        // Desktop: hover to show
        annotation.addEventListener('mouseenter', function() {
          showTooltip(annotation);
        });

        annotation.addEventListener('mouseleave', function() {
          hideTooltip();
        });
      }

      // Keyboard: Enter to show, Escape to hide
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

    // Click outside to close (for touch devices)
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

    // Carousel state
    const carousel = {
      track: document.querySelector('.recommendations .carousel-track'),
      slides: document.querySelectorAll('.recommendations .carousel-slide'),
      prevBtn: document.querySelector('.recommendations .carousel-arrow.prev'),
      nextBtn: document.querySelector('.recommendations .carousel-arrow.next'),
      dots: document.querySelectorAll('.recommendations .carousel-dot'),
      currentIndex: 0,
      totalSlides: 4,
      isTransitioning: false,
      autoAdvanceInterval: null,
      autoAdvanceDelay: 6000
    };

    // Check for reduced motion preference
    const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    // Go to specific slide
    function goToSlide(index) {
      if (carousel.isTransitioning) return;

      carousel.isTransitioning = true;
      carousel.currentIndex = index;

      // Update transform
      const offset = -index * 100;
      carousel.track.style.transform = `translateX(${offset}%)`;

      // Update dots
      carousel.dots.forEach((dot, i) => {
        dot.classList.toggle('active', i === index);
      });

      // Update ARIA
      carousel.slides.forEach((slide, i) => {
        slide.setAttribute('aria-hidden', i !== index);
      });

      // Update ARIA live region
      const statusCurrent = document.getElementById('carousel-current');
      if (statusCurrent) {
        statusCurrent.textContent = index + 1;
      }

      setTimeout(() => {
        carousel.isTransitioning = false;
      }, 300);
    }

    // Next slide
    function nextSlide() {
      const next = (carousel.currentIndex + 1) % carousel.totalSlides;
      goToSlide(next);
    }

    // Previous slide
    function prevSlide() {
      const prev = (carousel.currentIndex - 1 + carousel.totalSlides) % carousel.totalSlides;
      goToSlide(prev);
    }

    // Auto-advance
    function startAutoAdvance() {
      if (carousel.autoAdvanceInterval || prefersReducedMotion) return;

      carousel.autoAdvanceInterval = setInterval(() => {
        nextSlide();
      }, carousel.autoAdvanceDelay);
    }

    function pauseAutoAdvance() {
      if (carousel.autoAdvanceInterval) {
        clearInterval(carousel.autoAdvanceInterval);
        carousel.autoAdvanceInterval = null;
      }
    }

    function resumeAutoAdvance() {
      pauseAutoAdvance();
      setTimeout(startAutoAdvance, 1000);
    }

    // Event listeners
    carousel.prevBtn.addEventListener('click', () => {
      prevSlide();
      pauseAutoAdvance();
    });

    carousel.nextBtn.addEventListener('click', () => {
      nextSlide();
      pauseAutoAdvance();
    });

    carousel.dots.forEach((dot, index) => {
      dot.addEventListener('click', () => {
        goToSlide(index);
        pauseAutoAdvance();
      });
    });

    // Pause on hover
    const container = document.querySelector('.recommendations');
    container.addEventListener('mouseenter', pauseAutoAdvance);
    container.addEventListener('mouseleave', resumeAutoAdvance);

    // Keyboard navigation
    document.addEventListener('keydown', (e) => {
      if (e.target.closest('.recommendations')) {
        if (e.key === 'ArrowLeft') {
          prevSlide();
          pauseAutoAdvance();
        } else if (e.key === 'ArrowRight') {
          nextSlide();
          pauseAutoAdvance();
        }
      }
    });

    // Touch/swipe support
    const isTouchDevice = window.matchMedia('(hover: none)').matches;
    let touchStartX = 0;
    let touchEndX = 0;
    const swipeThreshold = 50;

    function handleSwipe() {
      const diff = touchStartX - touchEndX;

      if (Math.abs(diff) > swipeThreshold) {
        if (diff > 0) {
          // Swipe left - next slide
          nextSlide();
        } else {
          // Swipe right - previous slide
          prevSlide();
        }
        pauseAutoAdvance();
        setTimeout(resumeAutoAdvance, 2000);
      }
    }

    container.addEventListener('touchstart', (e) => {
      touchStartX = e.changedTouches[0].screenX;
      pauseAutoAdvance();
    }, { passive: true });

    container.addEventListener('touchend', (e) => {
      touchEndX = e.changedTouches[0].screenX;
      handleSwipe();
    }, { passive: true });

    // Initialize
    goToSlide(0);
    startAutoAdvance();

    // Pause when tab not visible
    document.addEventListener('visibilitychange', () => {
      if (document.hidden) {
        pauseAutoAdvance();
      } else {
        resumeAutoAdvance();
      }
    });
  })();

  (function() {
    'use strict';

    // FAQ state
    const faq = {
      items: document.querySelectorAll('.faq .faq-item'),
      currentlyOpenIndex: null,
      isAnimating: false
    };

    if (faq.items.length === 0) return;

    // Toggle FAQ
    function toggleFaq(index) {
      if (faq.isAnimating) return;

      if (faq.currentlyOpenIndex === index) {
        // Clicking currently open FAQ - close it
        closeFaq(index);
        faq.currentlyOpenIndex = null;
      } else {
        // Opening a new FAQ
        if (faq.currentlyOpenIndex !== null) {
          closeFaq(faq.currentlyOpenIndex);
        }
        openFaq(index);
        faq.currentlyOpenIndex = index;
      }
    }

    // Open FAQ
    function openFaq(index) {
      const item = faq.items[index];
      const button = item.querySelector('.faq-question');
      const answer = item.querySelector('.faq-answer');

      faq.isAnimating = true;

      // Set max-height to scrollHeight for smooth animation
      answer.style.maxHeight = answer.scrollHeight + 'px';

      // Update visual state
      button.classList.add('active');
      button.setAttribute('aria-expanded', 'true');

      // Clear animation lock after transition
      setTimeout(() => { faq.isAnimating = false; }, 300);
    }

    // Close FAQ
    function closeFaq(index) {
      const item = faq.items[index];
      const button = item.querySelector('.faq-question');
      const answer = item.querySelector('.faq-answer');

      faq.isAnimating = true;

      // Collapse to 0 height
      answer.style.maxHeight = '0';

      // Update visual state
      button.classList.remove('active');
      button.setAttribute('aria-expanded', 'false');

      setTimeout(() => { faq.isAnimating = false; }, 300);
    }

    // Click event listeners
    faq.items.forEach((item, index) => {
      const button = item.querySelector('.faq-question');

      button.addEventListener('click', (e) => {
        e.preventDefault();
        toggleFaq(index);
      });
    });

    // Keyboard event listeners
    document.addEventListener('keydown', (e) => {
      if (e.target.classList.contains('faq-question')) {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          const index = Array.from(faq.items).indexOf(e.target.closest('.faq-item'));
          toggleFaq(index);
        } else if (e.key === 'Escape' && faq.currentlyOpenIndex !== null) {
          e.preventDefault();
          closeFaq(faq.currentlyOpenIndex);
          faq.currentlyOpenIndex = null;
        }
      }
    });
  })();

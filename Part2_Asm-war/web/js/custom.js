(function ($) {

  "use strict";

  // PRE LOADER
  $(window).load(function () {
    $('.preloader').fadeOut(1000); // set duration in brackets    
  });


  //Navigation Section
  $('.navbar-collapse a').on('click', function () {
    $(".navbar-collapse").collapse('hide');
  });


  // Owl Carousel
  $('.owl-carousel').owlCarousel({
    animateOut: 'fadeOut',
    items: 1,
    loop: true,
    autoplay: true,
  })


  // PARALLAX EFFECT
  $.stellar();


  // SMOOTHSCROLL
  $(function () {
    $('.navbar-default a, #home a, footer a').on('click', function (event) {
      var $anchor = $(this);
      $('html, body').stop().animate({
        scrollTop: $($anchor.attr('href')).offset().top - 49
      }, 1000);
      event.preventDefault();
    });
  });


  // WOW ANIMATION
  new WOW({ mobile: false }).init();

  // TREATMENT REDIRECTION
  function redirectToTreatment(treatmentId) {
    // Validate treatment ID
    if (!treatmentId || treatmentId <= 0) {
      console.error('Invalid treatment ID:', treatmentId);
      alert('Error: Invalid treatment selected. Please try again.');
      return;
    }

    // Redirect to treatment description page
    window.location.href = 'treatment_description.jsp?id=' + treatmentId;
  }

  // Treatment click handlers
  $(document).ready(function () {
    // Handle clicks on treatment images and names
    $('.clickable-treatment').on('click', function() {
      var treatmentContainer = $(this).closest('[data-treatment-id]');
      var treatmentId = treatmentContainer.data('treatment-id');
      
      if (treatmentId) {
        redirectToTreatment(treatmentId);
      } else {
        console.error('Treatment ID not found');
      }
    });

    // Add hover effects for better UX
    $('.clickable-treatment').hover(
      function () {
        $(this).addClass('treatment-hover');
        $(this).css('cursor', 'pointer');
      },
      function () {
        $(this).removeClass('treatment-hover');
      }
    );
  });


})(jQuery);

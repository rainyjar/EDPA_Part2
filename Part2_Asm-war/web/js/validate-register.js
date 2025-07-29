$(document).ready(function () {
    // Common file upload handling
    $('#profilePic').change(function () {
        const file = this.files[0];
        const label = $('#fileLabel');

        if (file) {
            label.addClass('has-file');
            label.find('span').text(file.name);
            label.find('i').removeClass('fa-cloud-upload').addClass('fa-check');
            $(this).removeClass('is-invalid').addClass('is-valid');
            $(this).next().find('.invalid-feedback').hide();
        } else {
            label.removeClass('has-file');
            label.find('span').text('Choose Profile Picture');
            label.find('i').removeClass('fa-check').addClass('fa-cloud-upload');
        }
    });

    // Doctor Form validation
    $('#doctorForm').submit(function (e) {
        let isValid = validateForm('doctor');
        if (!isValid) {
            e.preventDefault();
            scrollToFirstError();
        } else {
            showLoadingState('#submitBtn', 'Registering...');
        }
    });

    // Counter Staff Form validation
    $('#staffForm').submit(function (e) {
        let isValid = validateForm('staff');
        if (!isValid) {
            e.preventDefault();
            scrollToFirstError();
        } else {
            showLoadingState('#submitBtn', 'Registering...');
        }
    });

    // Manager Form validation
    $('#managerForm').submit(function (e) {
        let isValid = validateForm('manager');
        if (!isValid) {
            e.preventDefault();
            scrollToFirstError();
        } else {
            showLoadingState('#submitBtn', 'Registering...');
        }
    });
    
     // Customer Form validation
    $('#customerForm').submit(function (e) {
        let isValid = validateForm('customer');
        if (!isValid) {
            e.preventDefault();
            scrollToFirstError();
        } else {
            showLoadingState('#submitBtn', 'Registering...');
        }
    });

    // Common validation function for all forms
    function validateForm(type) {
        let isValid = true;

        // Reset previous validation
        $('.form-control').removeClass('is-invalid is-valid');
        $('.invalid-feedback').empty();

        // Validate name
        const name = $('#name').val().trim();
        if (!name) {
            showError('#name', 'Full name is required');
            isValid = false;
        } else if (name.length < 2) {
            showError('#name', 'Name must be at least 2 characters');
            isValid = false;
        } else {
            showValid('#name');
        }

        // Validate email
        const email = $('#email').val().trim();
        const emailRegex = /^[a-zA-Z0-9_+&*-]+(?:\.[a-zA-Z0-9_+&*-]+)*@(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,7}$/;
        if (!email) {
            showError('#email', 'Email address is required');
            isValid = false;
        } else if (!emailRegex.test(email)) {
            showError('#email', 'Please enter a valid email address');
            isValid = false;
        } else {
            showValid('#email');
        }

        // Validate password
        const password = $('#password').val();
        if (!password) {
            showError('#password', 'Password is required');
            isValid = false;
        } else if (password.length < 6) {
            showError('#password', 'Password must be at least 6 characters');
            isValid = false;
        } else {
            showValid('#password');
        }

        // Validate phone
        const phone = $('#phone').val().trim();
        const phoneRegex = /^[\+]?[0-9\s\-\(\)]{10,15}$/;
        if (!phone) {
            showError('#phone', 'Phone number is required');
            isValid = false;
        } else if (!phoneRegex.test(phone)) {
            showError('#phone', 'Please enter a valid phone number');
            isValid = false;
        } else {
            showValid('#phone');
        }

        // Validate gender
        if (!$('#gender').val()) {
            showError('#gender', 'Please select gender');
            isValid = false;
        } else {
            showValid('#gender');
        }

        // Validate date of birth with type-specific age requirements
        const dob = $('#dob').val();
        if (!dob) {
            showError('#dob', 'Date of birth is required');
            isValid = false;
        } else {
            const today = new Date();
            const dobDate = new Date(dob);
            const age = Math.floor((today - dobDate) / (365.25 * 24 * 60 * 60 * 1000));

            if (dobDate >= today) {
                showError('#dob', 'Date of birth cannot be in the future');
                isValid = false;
            } else {
                // Type-specific age validation
                let minAge, ageMessage;
                switch (type) {
                    case 'doctor':
                        minAge = 18;
                        ageMessage = 'Doctor must be at least 18 years old';
                        break;
                    case 'staff':
                        minAge = 16;
                        ageMessage = 'Staff member must be at least 16 years old';
                        break;
                    case 'manager':
                        minAge = 21;
                        ageMessage = 'Manager must be at least 21 years old';
                        break;
                     case 'customer':
                        minAge = 1;
                        ageMessage = 'Customer must be at least 1 years old';
                        break;    
                    default:
                        minAge = 18;
                        ageMessage = 'Must be at least 18 years old';
                }

                if (age < minAge) {
                    showError('#dob', ageMessage);
                    isValid = false;
                } else if (age > 100) {
                    showError('#dob', 'Please enter a valid date of birth');
                    isValid = false;
                } else {
                    showValid('#dob');
                }
            }
        }

        // Validate specialization (only for doctors)
        if (type === 'doctor') {
            const specialization = $('#specialization').val().trim();
            if (!specialization) {
                showError('#specialization', 'Medical specialization is required');
                isValid = false;
            } else if (specialization.length < 2) {
                showError('#specialization', 'Specialization must be at least 2 characters');
                isValid = false;
            } else {
                showValid('#specialization');
            }
        }

        // Validate profile picture
        const profilePic = $('#profilePic')[0].files[0];
        if (!profilePic) {
            showError('#profilePic', 'Profile picture is required');
            console.log("Profile picture is required");
            isValid = false;
        } else {
            const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
            const maxSize = 5 * 1024 * 1024; // 5MB

            if (!allowedTypes.includes(profilePic.type)) {
                showError('#profilePic', 'Only JPEG, PNG, and GIF images are allowed');
                console.log("Only JPEG, PNG, and GIF images are allowed");
                isValid = false;
            } else if (profilePic.size > maxSize) {
                showError('#profilePic', 'Image size must be less than 5MB');
                isValid = false;
            } else {
                showValid('#profilePic');
                console.log('Profile picture validation passed');
            }
        }

        return isValid;
    }

    // Helper function to show error
    function showError(selector, message) {
        const input = $(selector);

        if (selector === '#profilePic') {
            input.removeClass('is-valid').addClass('is-invalid');
            const label = $('#fileLabel');
            label.addClass('is-invalid-label').removeClass('is-valid-label');
            input.closest('.file-upload').find('.invalid-feedback').text(message).show();
        } else {
            input.addClass('is-invalid').removeClass('is-valid');
            input.siblings('.invalid-feedback').text(message).show();
        }
    }

    function showValid(selector) {
        const input = $(selector);

        if (selector === '#profilePic') {
            input.removeClass('is-invalid').addClass('is-valid');
            const label = $('#fileLabel');
            label.removeClass('is-invalid-label').addClass('is-valid-label');
            input.closest('.file-upload').find('.invalid-feedback').text('').hide();
        } else {
            input.addClass('is-valid').removeClass('is-invalid');
            input.siblings('.invalid-feedback').text('').hide();
        }
    }

    // Helper function to scroll to first error
    function scrollToFirstError() {
        const firstError = $('.is-invalid').first();
        if (firstError.length) {
            $('html, body').animate({
                scrollTop: firstError.offset().top - 100
            }, 500);
        }
    }

    // Helper function to show loading state
    function showLoadingState(buttonSelector, loadingText) {
        const submitBtn = $(buttonSelector);
        submitBtn.addClass('loading');
        submitBtn.find('.btn-text').text(loadingText);
    }
});
  
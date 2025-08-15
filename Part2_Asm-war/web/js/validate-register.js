$(document).ready(function () {
    // Common file upload handling
    $('#profilePic').on('change', function () {
        const file = this.files[0];
        const label = $('#fileLabel');
        const labelSpan = $('#fileLabel span');
        const labelIcon = $('#fileLabel i');
        const errorMsg = $('#profilePicError'); // target only this

        // Reset state
        label.removeClass('is-valid-label is-invalid-label');
        labelIcon.removeClass('fa-check fa-times');
        $('#profilePic').removeClass('is-valid is-invalid');
        errorMsg.hide().text('');

        if (file) {
            const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png'];
            const maxSize = 5 * 1024 * 1024;

            labelSpan.text(file.name);

            if (!allowedTypes.includes(file.type) || file.type === 'image/gif') {
                label.addClass('is-invalid-label');
                labelIcon.addClass('fa-times');
                $('#profilePic').addClass('is-invalid');
                errorMsg.text('Only JPEG and PNG images are allowed (GIFs are not accepted)').show();
            } else if (file.size > maxSize) {
                label.addClass('is-invalid-label');
                labelIcon.addClass('fa-times');
                $('#profilePic').addClass('is-invalid');
                errorMsg.text('Image size must be less than 5MB').show();
            } else {
                label.addClass('is-valid-label');
                labelIcon.addClass('fa-check');
                $('#profilePic').addClass('is-valid');
                errorMsg.hide().text(''); // hide previous error if any

            }

        } else {
            labelSpan.text('Choose Profile Picture');
            labelIcon.removeClass('fa-check fa-times');
            $('#profilePic').removeClass('is-valid is-invalid');
            label.removeClass('is-valid-label is-invalid-label');
            errorMsg.hide().text('');
        }
    });

    // Form submission handlers
    $('#doctorForm, #staffForm, #managerForm, #customerForm').submit(function (e) {
        let formType = this.id.replace('Form', '');
        let isValid = validateForm(formType);
        if (!isValid) {
            e.preventDefault();
            scrollToFirstError();
        } else {
            showLoadingState('#submitBtn', 'Loading...');
        }
    });

    function validateForm(type) {
        let isValid = true;

        // Reset validation styles
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
        const phoneRegex = /^[\+]?[0-9\s\-\(\)]{9,12}$/;
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

        // Validate date of birth
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
                let minAge = 18, ageMessage = 'Must be at least 18 years old';
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
                        ageMessage = 'Customer must be at least 1 year old';
                        break;
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

        // Validate NRIC (Malaysia format: 12 digits, typically xxxxxx-xx-xxxx)
        const nric = $('#nric').val().trim();
        const nricRegex = /^\d{6}-\d{2}-\d{4}$/;
        if (!nric) {
            showError('#nric', 'NRIC is required');
            isValid = false;
        } else if (!nricRegex.test(nric)) {
            showError('#nric', 'Please enter a valid NRIC (e.g. 990101-14-5678)');
            isValid = false;
        } else {
            // Check if NRIC is already in use
            const currentUserId = $('#userId').val() || 0; // Get current user ID if editing
            
            // Determine user type based on form
            let userType = '';
            if (type === 'doctor') {
                userType = 'doctor';
            } else if (type === 'staff') {
                userType = 'counterstaff';
            } else if (type === 'manager') {
                userType = 'manager';
            } else {
                userType = 'customer';
            }
            
            $.ajax({
                url: `${window.location.origin}/Part2_Asm-war/CheckNRICServlet`,
                method: 'GET',
                data: { 
                    nric: nric, 
                    userId: currentUserId,
                    userType: userType
                },
                async: false, // Make synchronous to ensure validation completes before form submission
                success: function(response) {
                    if (response === 'taken') {
                        showError('#nric', 'This NRIC is already registered to another user');
                        isValid = false;
                    } else {
                        showValid('#nric');
                    }
                },
                error: function() {
                    // If check fails, allow submission but log warning
                    console.warn('NRIC uniqueness check failed');
                    showValid('#nric');
                }
            });
        }

        // Validate address
        const address = $('#address').val().trim();
        if (!address) {
            showError('#address', 'Address is required');
            isValid = false;
        } else if (address.length < 10) {
            showError('#address', 'Address must be at least 10 characters long');
            isValid = false;
        } else {
            showValid('#address');
        }

        // Validate specialization
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
        const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
        const maxSize = 5 * 1024 * 1024;

        if (!profilePic) {
            showError('#profilePic', 'Profile picture is required');
            isValid = false;
        } else if (!allowedTypes.includes(profilePic.type)) {
            showError('#profilePic', 'Only JPEG, PNG, and GIF images are allowed');
            isValid = false;
        } else if (profilePic.size > maxSize) {
            showError('#profilePic', 'Image size must be less than 5MB');
            isValid = false;
        } else {
            showValid('#profilePic');
        }

        return isValid;
    }

    // Show error message
    function showError(selector, message) {
        const input = $(selector);
        const label = $('#fileLabel');

        if (selector === '#profilePic') {
            input.removeClass('is-valid').addClass('is-invalid');
            label.removeClass('is-valid-label').addClass('is-invalid-label');
            input.closest('.file-upload').find('.invalid-feedback').text(message).show();
        } else {
            input.addClass('is-invalid').removeClass('is-valid');
            input.siblings('.invalid-feedback').text(message).show();
        }
    }

    // Show valid feedback
    function showValid(selector) {
        const input = $(selector);
        const label = $('#fileLabel');

        if (selector === '#profilePic') {
            input.removeClass('is-invalid').addClass('is-valid');
            label.removeClass('is-invalid-label').addClass('is-valid-label');
            input.closest('.file-upload').find('.invalid-feedback').text('').hide();
        } else {
            input.addClass('is-valid').removeClass('is-invalid');
            input.siblings('.invalid-feedback').text('').hide();
        }
    }

    // Scroll to first error
    function scrollToFirstError() {
        const firstError = $('.is-invalid').first();
        if (firstError.length) {
            $('html, body').animate({scrollTop: firstError.offset().top - 100}, 500);
        }
    }

    // Show loading state
    function showLoadingState(buttonSelector, loadingText) {
        const submitBtn = $(buttonSelector);
        submitBtn.addClass('loading');
        submitBtn.find('.btn-text').text(loadingText);
    }
});

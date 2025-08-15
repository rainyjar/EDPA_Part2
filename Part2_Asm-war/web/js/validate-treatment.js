$(document).ready(function () {
    console.log('Treatment validation script loaded');

    // Treatment file upload handling
    $('#treatmentPic').on('change', function () {
        const file = this.files[0];
        const label = $('#fileLabel');
        const labelSpan = $('#fileLabel span');
        const labelIcon = $('#fileLabel i');
        const errorMsg = $('#treatmentPicError');

        console.log('File selected:', file ? file.name : 'None');

        // Reset state
        label.removeClass('is-valid-label is-invalid-label');
        labelIcon.removeClass('fa-check fa-times fa-cloud-upload');
        $('#treatmentPic').removeClass('is-valid is-invalid');
        errorMsg.hide().text('');

        if (file) {
            const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
            const maxSize = 5 * 1024 * 1024; // 5MB

            labelSpan.text(file.name);

            if (!allowedTypes.includes(file.type)) {
                label.addClass('is-invalid-label');
                labelIcon.addClass('fa-times');
                $('#treatmentPic').addClass('is-invalid');
                errorMsg.text('Only JPEG, PNG, and GIF images are allowed').show();
                console.log('Invalid file type:', file.type);
            } else if (file.size > maxSize) {
                label.addClass('is-invalid-label');
                labelIcon.addClass('fa-times');
                $('#treatmentPic').addClass('is-invalid');
                errorMsg.text('Image size must be less than 5MB (Current: ' + (file.size / (1024*1024)).toFixed(2) + 'MB)').show();
                console.log('File too large:', file.size);
            } else {
                label.addClass('is-valid-label');
                labelIcon.addClass('fa-check');
                $('#treatmentPic').addClass('is-valid');
                errorMsg.hide().text('');
                console.log('File valid:', file.name, 'Size:', (file.size / (1024*1024)).toFixed(2) + 'MB');
            }
        } else {
            labelSpan.text('Choose Treatment Image');
            labelIcon.addClass('fa-cloud-upload');
            $('#treatmentPic').removeClass('is-valid is-invalid');
            label.removeClass('is-valid-label is-invalid-label');
            errorMsg.hide().text('');
        }
    });

    // Form submission handler
    $('#treatmentForm').submit(function (e) {
        console.log('Treatment form submitted');
        console.log('Form data being submitted:');
        
        // Log form data for debugging
        const formData = new FormData(this);
        for (let [key, value] of formData.entries()) {
            if (value instanceof File) {
                console.log(`${key}: File - ${value.name} (${value.size} bytes)`);
            } else {
                console.log(`${key}: ${value}`);
            }
        }
        
        let isValid = validateTreatmentForm();
        
        if (!isValid) {
            e.preventDefault();
            console.log('Form validation failed - preventing submission');
            scrollToFirstError();
            
            // Show validation summary
            showValidationSummary();
        } else {
            console.log('Form validation passed - submitting');
            showLoadingState('#submitBtn', 'Creating Treatment...');
        }
    });

    // Real-time validation for required fields
    $('#name, #shortDesc, #baseCharge, #followUpCharge').on('input blur', function() {
        validateField(this);
    });

    // Real-time validation for prescription fields
    $(document).on('input blur', 'input[name="conditionName"], input[name="medicationName"]', function() {
        validatePrescriptionField(this);
    });

    function validateTreatmentForm() {
        console.log('Starting form validation');
        let isValid = true;
        let errors = [];

        // Reset validation styles
        $('.form-control').removeClass('is-invalid is-valid');
        $('.invalid-feedback').empty().hide();
        $('#treatmentPicError').hide().text('');

        // Validate treatment name
        const name = $('#name').val().trim();
        if (!name) {
            showError('#name', 'Treatment name is required');
            errors.push('Treatment name is required');
            isValid = false;
        } else if (name.length < 2) {
            showError('#name', 'Treatment name must be at least 2 characters');
            errors.push('Treatment name too short');
            isValid = false;
        } else if (name.length > 100) {
            showError('#name', 'Treatment name must be less than 100 characters');
            errors.push('Treatment name too long');
            isValid = false;
        } else {
            showValid('#name');
        }

        // Validate short description
        const shortDesc = $('#shortDesc').val().trim();
        if (!shortDesc) {
            showError('#shortDesc', 'Short description is required');
            errors.push('Short description is required');
            isValid = false;
        } else if (shortDesc.length < 10) {
            showError('#shortDesc', 'Short description must be at least 10 characters');
            errors.push('Short description too short');
            isValid = false;
        } else if (shortDesc.length > 500) {
            showError('#shortDesc', 'Short description must be less than 500 characters');
            errors.push('Short description too long');
            isValid = false;
        } else {
            showValid('#shortDesc');
        }

        // Validate long description (required)
        const longDesc = $('#longDesc').val().trim();
        if (!longDesc) {
            showError('#longDesc', 'Long description is required');
            errors.push('Long description required');
            isValid = false;
        } else if (longDesc.length > 2000) {
            showError('#longDesc', 'Long description must be less than 2000 characters');
            errors.push('Long description too long');
            isValid = false;
        } else {
            showValid('#longDesc');
        }

        // Validate base charge
        const baseCharge = $('#baseCharge').val();
        if (!baseCharge) {
            showError('#baseCharge', 'Base consultation charge is required');
            errors.push('Base charge is required');
            isValid = false;
        } else if (isNaN(baseCharge) || parseFloat(baseCharge) < 0) {
            showError('#baseCharge', 'Base charge must be a valid positive number');
            errors.push('Invalid base charge');
            isValid = false;
        } else if (parseFloat(baseCharge) > 10000) {
            showError('#baseCharge', 'Base charge seems unusually high (max RM 10,000)');
            errors.push('Base charge too high');
            isValid = false;
        } else {
            showValid('#baseCharge');
        }

        // Validate follow-up charge
        const followUpCharge = $('#followUpCharge').val();
        if (!followUpCharge) {
            showError('#followUpCharge', 'Follow-up charge is required');
            errors.push('Follow-up charge is required');
            isValid = false;
        } else if (isNaN(followUpCharge) || parseFloat(followUpCharge) < 0) {
            showError('#followUpCharge', 'Follow-up charge must be a valid positive number');
            errors.push('Invalid follow-up charge');
            isValid = false;
        } else if (parseFloat(followUpCharge) > 10000) {
            showError('#followUpCharge', 'Follow-up charge seems unusually high (max RM 10,000)');
            errors.push('Follow-up charge too high');
            isValid = false;
        } else {
            showValid('#followUpCharge');
        }

        // Validate treatment image
        const treatmentPic = $('#treatmentPic')[0].files[0];
        if (!treatmentPic) {
            showError('#treatmentPic', 'Treatment image is required');
            errors.push('Treatment image is required');
            isValid = false;
        } else {
            const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
            const maxSize = 5 * 1024 * 1024;

            if (!allowedTypes.includes(treatmentPic.type)) {
                showError('#treatmentPic', 'Only JPEG, PNG, and GIF images are allowed');
                errors.push('Invalid image type');
                isValid = false;
            } else if (treatmentPic.size > maxSize) {
                showError('#treatmentPic', 'Image size must be less than 5MB');
                errors.push('Image too large');
                isValid = false;
            } else {
                showValid('#treatmentPic');
            }
        }

        // Validate doctor assignments
        const assignedDoctors = $('#assignedDoctors').val();
        if (!assignedDoctors || assignedDoctors.length === 0) {
            showError('#assignedDoctors', 'At least one doctor must be assigned to the treatment');
            errors.push('No doctors assigned');
            isValid = false;
        } else {
            showValid('#assignedDoctors');
            console.log('Assigned doctors:', assignedDoctors.length);
        }

        // Validate prescriptions (optional but if provided, must be complete)
        const prescriptionRows = $('.prescription-row');
        let prescriptionErrors = 0;
        let validPrescriptions = 0;

        prescriptionRows.each(function() {
            const conditionName = $(this).find('input[name="conditionName"]').val().trim();
            const medicationName = $(this).find('input[name="medicationName"]').val().trim();

            if (conditionName && medicationName) {
                if (conditionName.length >= 2 && medicationName.length >= 2) {
                    validPrescriptions++;
                    showValid($(this).find('input[name="conditionName"]')[0]);
                    showValid($(this).find('input[name="medicationName"]')[0]);
                } else {
                    prescriptionErrors++;
                    if (conditionName.length < 2) {
                        showError($(this).find('input[name="conditionName"]')[0], 'Condition name must be at least 2 characters');
                    }
                    if (medicationName.length < 2) {
                        showError($(this).find('input[name="medicationName"]')[0], 'Medication name must be at least 2 characters');
                    }
                }
            } else if (conditionName || medicationName) {
                // Partial prescription - both fields required
                prescriptionErrors++;
                if (!conditionName) {
                    showError($(this).find('input[name="conditionName"]')[0], 'Condition name is required if medication is provided');
                }
                if (!medicationName) {
                    showError($(this).find('input[name="medicationName"]')[0], 'Medication name is required if condition is provided');
                }
            } else {
                // Both empty - clear any previous validation
                $(this).find('input[name="conditionName"], input[name="medicationName"]').removeClass('is-invalid is-valid');
            }
        });

        if (prescriptionErrors > 0) {
            errors.push(prescriptionErrors + ' prescription validation errors');
            isValid = false;
        }

        console.log('Validation result:', isValid ? 'PASSED' : 'FAILED');
        console.log('Valid prescriptions:', validPrescriptions);
        console.log('Prescription errors:', prescriptionErrors);
        console.log('All errors:', errors);

        return isValid;
    }

    function validateField(field) {
        const $field = $(field);
        const value = $field.val().trim();
        const fieldName = $field.attr('name') || $field.attr('id');

        switch (fieldName) {
            case 'name':
                if (!value) {
                    showError(field, 'Treatment name is required');
                } else if (value.length < 2) {
                    showError(field, 'Treatment name must be at least 2 characters');
                } else if (value.length > 100) {
                    showError(field, 'Treatment name must be less than 100 characters');
                } else {
                    showValid(field);
                }
                break;

            case 'shortDesc':
                if (!value) {
                    showError(field, 'Short description is required');
                } else if (value.length < 10) {
                    showError(field, 'Short description must be at least 10 characters');
                } else if (value.length > 500) {
                    showError(field, 'Short description must be less than 500 characters');
                } else {
                    showValid(field);
                }
                break;

            case 'longDesc':
                if (!value) {
                    showError(field, 'Long description is required');
                } else if (value.length > 2000) {
                    showError(field, 'Long description must be less than 2000 characters');
                } else {
                    showValid(field);
                }
                break;

            case 'baseCharge':
            case 'followUpCharge':
                if (!value) {
                    showError(field, `${fieldName === 'baseCharge' ? 'Base consultation' : 'Follow-up'} charge is required`);
                } else if (isNaN(value) || parseFloat(value) < 0) {
                    showError(field, 'Charge must be a valid positive number');
                } else if (parseFloat(value) > 10000) {
                    showError(field, 'Charge seems unusually high (max RM 10,000)');
                } else {
                    showValid(field);
                }
                break;
        }
    }

    function validatePrescriptionField(field) {
        const $field = $(field);
        const value = $field.val().trim();
        const fieldName = $field.attr('name');

        if (value && value.length < 2) {
            showError(field, `${fieldName === 'conditionName' ? 'Condition' : 'Medication'} name must be at least 2 characters`);
        } else if (value && value.length > 100) {
            showError(field, `${fieldName === 'conditionName' ? 'Condition' : 'Medication'} name must be less than 100 characters`);
        } else if (value) {
            showValid(field);
        } else {
            // Clear validation state if empty
            $field.removeClass('is-invalid is-valid');
            $field.siblings('.invalid-feedback').hide();
        }
    }

    // Show error message
    function showError(selector, message) {
        const input = $(selector);
        const label = $('#fileLabel');

        console.log('Showing error for', selector, ':', message);

        if (selector === '#treatmentPic' || input.attr('id') === 'treatmentPic') {
            input.removeClass('is-valid').addClass('is-invalid');
            label.removeClass('is-valid-label').addClass('is-invalid-label');
            $('#treatmentPicError').text(message).show();
        } else {
            input.addClass('is-invalid').removeClass('is-valid');
            input.siblings('.invalid-feedback').text(message).show();
        }
    }

    // Show valid feedback
    function showValid(selector) {
        const input = $(selector);
        const label = $('#fileLabel');

        if (selector === '#treatmentPic' || input.attr('id') === 'treatmentPic') {
            input.removeClass('is-invalid').addClass('is-valid');
            label.removeClass('is-invalid-label').addClass('is-valid-label');
            $('#treatmentPicError').text('').hide();
        } else {
            input.addClass('is-valid').removeClass('is-invalid');
            input.siblings('.invalid-feedback').text('').hide();
        }
    }

    // Show validation summary
    function showValidationSummary() {
        const errors = [];
        $('.is-invalid').each(function() {
            const fieldName = $(this).attr('id') || $(this).attr('name') || 'Unknown field';
            const errorMessage = $(this).siblings('.invalid-feedback').text() || $('#treatmentPicError').text();
            if (errorMessage) {
                errors.push(`${fieldName}: ${errorMessage}`);
            }
        });

        if (errors.length > 0) {
            console.log('Validation Summary - ' + errors.length + ' errors found:');
            errors.forEach((error, index) => {
                console.log(`  ${index + 1}. ${error}`);
            });
            
            // Show an alert with the first few errors
            const maxErrorsToShow = 3;
            let alertMessage = 'Please fix the following errors:\n\n';
            for (let i = 0; i < Math.min(errors.length, maxErrorsToShow); i++) {
                alertMessage += `• ${errors[i]}\n`;
            }
            if (errors.length > maxErrorsToShow) {
                alertMessage += `\n... and ${errors.length - maxErrorsToShow} more error(s)`;
            }
            
            alert(alertMessage);
        }
    }

    // Scroll to first error
    function scrollToFirstError() {
        const firstError = $('.is-invalid').first();
        if (firstError.length) {
            console.log('Scrolling to first error:', firstError.attr('id') || firstError.attr('name'));
            $('html, body').animate({scrollTop: firstError.offset().top - 100}, 500);
            firstError.focus();
        }
    }

    // Show loading state
    function showLoadingState(buttonSelector, loadingText) {
        const submitBtn = $(buttonSelector);
        submitBtn.addClass('loading');
        submitBtn.find('.btn-text').text(loadingText);
        submitBtn.prop('disabled', true);
        
        // Add spinner
        submitBtn.find('i').removeClass('fa-save').addClass('fa-spinner fa-spin');
    }

    // Prescription management functions (already exist in the page)
    window.addPrescription = function() {
        console.log('Adding new prescription row');
        const container = document.getElementById('prescriptionContainer');
        const prescriptionRow = document.createElement('div');
        prescriptionRow.className = 'prescription-row';
        prescriptionRow.innerHTML = `
            <div class="form-row">
                <div class="form-group">
                    <label>Condition Name</label>
                    <input type="text" class="form-control doctor" name="conditionName" 
                           placeholder="e.g., Hypertension">
                    <div class="invalid-feedback"></div>
                </div>
                <div class="form-group">
                    <label>Medication Name</label>
                    <input type="text" class="form-control doctor" name="medicationName" 
                           placeholder="e.g., Lisinopril 10mg">
                    <div class="invalid-feedback"></div>
                </div>
            </div>
            <div class="form-group" style="text-align: center;">
                <button type="button" class="btn btn-danger remove-prescription" 
                        onclick="removePrescription(this)">
                    <i class="fa fa-trash"></i> Remove
                </button>
            </div>
        `;
        container.appendChild(prescriptionRow);
        updateRemoveButtons();
        
        // Focus on the first input of the new row
        $(prescriptionRow).find('input[name="conditionName"]').focus();
    };

    window.removePrescription = function(button) {
        console.log('Removing prescription row');
        const prescriptionRow = button.closest('.prescription-row');
        
        // Add animation effect
        $(prescriptionRow).fadeOut(300, function() {
            this.remove();
            updateRemoveButtons();
        });
    };

    window.updateRemoveButtons = function() {
        const rows = document.querySelectorAll('.prescription-row');
        rows.forEach((row, index) => {
            const removeBtn = row.querySelector('.remove-prescription');
            if (rows.length > 1) {
                removeBtn.style.display = 'inline-block';
            } else {
                removeBtn.style.display = 'none';
            }
        });
    };

    // Initialize remove buttons on page load
    updateRemoveButtons();
});

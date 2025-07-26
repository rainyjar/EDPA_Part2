// Dynamic Appointment Booking JavaScript
document.addEventListener('DOMContentLoaded', function() {
    // Detect which page we're on
    const isReschedulePage = document.getElementById('reschedule-form') !== null;
    const isAppointmentPage = document.getElementById('appointment-form') !== null;
    
    if (isReschedulePage) {
        initializeRescheduleForm();
    } else if (isAppointmentPage) {
        initializeAppointmentBooking();
    }
});

// Shared utility functions
function formatDateForInput(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
}

function validateWeekday(dateValue) {
    if (!dateValue) return false;
    
    const selectedDate = new Date(dateValue + 'T00:00:00');
    const dayOfWeek = selectedDate.getDay(); // 0 = Sunday, 6 = Saturday
    const now = new Date();
    const currentHour = now.getHours();
    const today = new Date();
    today.setHours(0, 0, 0, 0); // Reset time to compare dates only
    selectedDate.setHours(0, 0, 0, 0);
    
    // Check if selected date is a weekend
    if (dayOfWeek === 0 || dayOfWeek === 6) {
        alert('Appointments are only available on weekdays (Monday to Friday). Please select a weekday within the booking range.');
        const dateInput = document.getElementById('appointment_date');
        if (dateInput) dateInput.value = '';
        return false;
    }
    
    // Check if user is trying to select today after business hours
    if (selectedDate.getTime() === today.getTime() && currentHour >= 17) {
        alert('Appointments for today cannot be booked after 5:00 PM. Please select a future weekday.');
        const dateInput = document.getElementById('appointment_date');
        if (dateInput) dateInput.value = '';
        return false;
    }
    
    // Check if selected date is in the past
    if (selectedDate.getTime() < today.getTime()) {
        alert('Cannot select a past date. Please select a current or future weekday.');
        const dateInput = document.getElementById('appointment_date');
        if (dateInput) dateInput.value = '';
        return false;
    }
    
    return true;
}

function isTimeSlotAvailableToday(timeSlot) {
    const now = new Date();
    const currentHour = now.getHours();
    const currentMinute = now.getMinutes();
    
    // Parse the time slot (format: "14:30")
    const [slotHour, slotMinute] = timeSlot.split(':').map(Number);
    
    // Convert current time and slot time to minutes for easier comparison
    const currentTimeInMinutes = currentHour * 60 + currentMinute;
    const slotTimeInMinutes = slotHour * 60 + slotMinute;
    
    // Add 30 minutes buffer - user must book at least 30 minutes in advance
    const minimumAdvanceTimeInMinutes = currentTimeInMinutes + 30;
    
    return slotTimeInMinutes >= minimumAdvanceTimeInMinutes;
}

function setupDateInputRestrictions(dateInput) {
    if (!dateInput) return;
    
    const now = new Date();
    const currentHour = now.getHours();
    
    // Determine the minimum selectable date based on current time
    let minDate = new Date();
    
    // If it's after 5 PM (17:00), users cannot book for today
    if (currentHour >= 17) {
        minDate.setDate(minDate.getDate() + 1);
    }
    
    // Maximum date is exactly 6 days from TODAY (making it 7 days total including today)
    // This ensures the booking window is always exactly 7 days from today, regardless of when you start booking
    const maxDate = new Date();
    maxDate.setDate(maxDate.getDate() + 6);
    
    // Set min and max dates - the range is fixed, weekday validation happens separately
    dateInput.min = formatDateForInput(minDate);
    dateInput.max = formatDateForInput(maxDate);
    
    // Prevent manual typing but allow calendar picker
    // Remove readonly attribute to allow calendar picker
    dateInput.removeAttribute('readonly');
    
    // Prevent keyboard input (typing) while allowing calendar picker
    dateInput.addEventListener('keydown', function(e) {
        // Allow navigation keys (tab, arrow keys, etc.) but prevent typing
        const allowedKeys = [
            'Tab', 'Escape', 'Enter', 'Backspace', 'Delete',
            'ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown',
            'Home', 'End', 'PageUp', 'PageDown'
        ];
        
        if (!allowedKeys.includes(e.key)) {
            e.preventDefault();
        }
    });
    
    // Prevent paste operations
    dateInput.addEventListener('paste', function(e) {
        e.preventDefault();
    });
    
    // Prevent text selection for a cleaner UX
    dateInput.addEventListener('selectstart', function(e) {
        e.preventDefault();
    });
}

function generateDoctorCards(selectedDate, treatmentId) {
    const container = document.getElementById('doctor-cards-container');
    if (!container) return;
    
    // Clear existing cards
    container.innerHTML = '<p>Loading available doctors and time slots...</p>';
    
    // Get available doctors and generate cards
    if (window.doctorData && window.doctorData.length > 0) {
        let cardsHtml = '';
        
        window.doctorData.forEach(function(doctor) {
            const doctorCard = `
                <div class="doctor-card" data-doctor-id="${doctor.id}">
                    <div class="doctor-info">
                        <h5>${doctor.name}</h5>
                        <p class="specialization">${doctor.specialization || 'General Practice'}</p>
                    </div>
                    <div class="time-slots">
                        <label><strong>Available Time Slots:</strong></label>
                        <div class="time-slots-grid">
                            <button type="button" class="time-slot-btn" data-time="09:00">09:00 AM</button>
                            <button type="button" class="time-slot-btn" data-time="09:30">09:30 AM</button>
                            <button type="button" class="time-slot-btn" data-time="10:00">10:00 AM</button>
                            <button type="button" class="time-slot-btn" data-time="10:30">10:30 AM</button>
                            <button type="button" class="time-slot-btn" data-time="11:00">11:00 AM</button>
                            <button type="button" class="time-slot-btn" data-time="11:30">11:30 AM</button>
                            <button type="button" class="time-slot-btn" data-time="14:00">02:00 PM</button>
                            <button type="button" class="time-slot-btn" data-time="14:30">02:30 PM</button>
                            <button type="button" class="time-slot-btn" data-time="15:00">03:00 PM</button>
                            <button type="button" class="time-slot-btn" data-time="15:30">03:30 PM</button>
                            <button type="button" class="time-slot-btn" data-time="16:00">04:00 PM</button>
                            <button type="button" class="time-slot-btn" data-time="16:30">04:30 PM</button>
                        </div>
                    </div>
                </div>
            `;
            cardsHtml += doctorCard;
        });
        
        container.innerHTML = cardsHtml;
        
        // Add event listeners to doctor cards and time slots
        setupDoctorCardListeners();
    } else {
        container.innerHTML = '<p class="text-danger">No doctors available. Please try again later.</p>';
    }
}

function setupDoctorCardListeners() {
    const timeSlotButtons = document.querySelectorAll('.time-slot-btn');
    
    // Handle time slot selection
    timeSlotButtons.forEach(function(button) {
        button.addEventListener('click', function() {
            const doctorCard = this.closest('.doctor-card');
            const doctorId = doctorCard.getAttribute('data-doctor-id');
            const timeSlot = this.getAttribute('data-time');
            
            // Clear all previous selections
            document.querySelectorAll('.doctor-card').forEach(card => card.classList.remove('selected'));
            document.querySelectorAll('.time-slot-btn').forEach(btn => btn.classList.remove('selected'));
            
            // Select this doctor and time slot
            doctorCard.classList.add('selected');
            this.classList.add('selected');
            
            // Set hidden form values
            document.getElementById('selected_doctor_id').value = doctorId;
            document.getElementById('selected_time_slot').value = timeSlot;
            
            // Move to message section (different for each page)
            const isReschedulePage = document.getElementById('reschedule-form') !== null;
            if (isReschedulePage) {
                showRescheduleSection('message-section');
                updateRescheduleStepIndicator(4);
            } else {
                showSection('message-section');
                updateStepIndicator(4);
            }
        });
    });
}

// RESCHEDULE PAGE SPECIFIC FUNCTIONS
function initializeRescheduleForm() {
    const treatmentSelect = document.getElementById('treatment');
    const dateInput = document.getElementById('appointment_date');
    const submitBtn = document.getElementById('submit-reschedule');
    const finalConfirmBtn = document.getElementById('final-confirm');
    const form = document.getElementById('reschedule-form');
    
    // Initialize by showing treatment section first
    showRescheduleSection('treatment-section');
    updateRescheduleStepIndicator(1);
    
    // Setup date restrictions (readonly for both pages)
    setupDateInputRestrictions(dateInput);
    
    // Add date change event listener
    if (dateInput) {
        dateInput.addEventListener('change', function() {
            if (this.value && validateWeekday(this.value)) {
                const treatmentId = document.getElementById('treatment').value;
                if (treatmentId) {
                    generateDoctorCards(this.value, treatmentId);
                    showRescheduleSection('doctor-section');
                    updateRescheduleStepIndicator(3);
                }
            }
        });
    }
    
    // Step 1: Treatment selection
    if (treatmentSelect) {
        treatmentSelect.addEventListener('change', function() {
            if (this.value) {
                showRescheduleSection('date-section');
                updateRescheduleStepIndicator(2);
                
                // If date is already selected, load doctors immediately
                const dateValue = dateInput ? dateInput.value : null;
                if (dateValue && validateWeekday(dateValue)) {
                    generateDoctorCards(dateValue, this.value);
                    showRescheduleSection('doctor-section');
                    updateRescheduleStepIndicator(3);
                }
            }
        });
    }
    
    // Submit handlers
    if (submitBtn) {
        submitBtn.addEventListener('click', function() {
            if (validateRescheduleForm()) {
                showRescheduleConfirmationModal();
            }
        });
    }
    
    if (finalConfirmBtn) {
        finalConfirmBtn.addEventListener('click', function() {
            if (form) {
                form.submit();
            }
        });
    }
    
    // Auto-hide messages
    setTimeout(function() {
        const alerts = document.querySelectorAll('.alert');
        alerts.forEach(function(alert) {
            alert.style.opacity = '0';
            setTimeout(function() {
                alert.style.display = 'none';
            }, 500);
        });
    }, 5000);
    
    // Add click handlers for step navigation
    const stepIndicators = document.querySelectorAll('.step.clickable');
    stepIndicators.forEach(function(step) {
        step.addEventListener('click', function() {
            const targetSection = this.getAttribute('data-section');
            const stepNumber = parseInt(this.id.replace('step', ''));
            
            if (targetSection && validateRescheduleStepNavigation(stepNumber)) {
                showRescheduleSection(targetSection);
                updateRescheduleStepIndicator(stepNumber);
            }
        });
    });
}

function validateRescheduleStepNavigation(targetStep) {
    const treatment = document.getElementById('treatment').value;
    const date = document.getElementById('appointment_date').value;
    const doctorId = document.getElementById('selected_doctor_id').value;
    const timeSlot = document.getElementById('selected_time_slot').value;
    
    // Always allow going back to step 1
    if (targetStep === 1) {
        return true;
    }
    
    // For step 2 (date), require treatment
    if (targetStep === 2) {
        if (!treatment) {
            alert('Please select a treatment first before choosing a date.');
            return false;
        }
        return true;
    }
    
    // For step 3 (doctor), check requirements in order
    if (targetStep === 3) {
        if (!treatment) {
            alert('Please select a treatment first before choosing a date.');
            return false;
        }
        if (!date) {
            alert('Please select a date first before choosing a doctor.');
            return false;
        }
        return true;
    }
    
    // For step 4 (message), check requirements in order
    if (targetStep === 4) {
        if (!treatment) {
            alert('Please select a treatment first before choosing a date.');
            return false;
        }
        if (!date) {
            alert('Please select a date first before choosing a doctor.');
            return false;
        }
        if (!doctorId || !timeSlot) {
            alert('Please select a doctor and time slot first.');
            return false;
        }
        return true;
    }
    
    return true;
}

function showRescheduleSection(sectionId) {
    // Hide all form sections first
    const sections = document.querySelectorAll('.form-section');
    sections.forEach(section => {
        section.style.display = 'none';
    });
    
    // Show the target section
    const section = document.getElementById(sectionId);
    if (section) {
        section.style.display = 'block';
    }
}

function updateRescheduleStepIndicator(activeStep) {
    // Update step indicator
    for (let i = 1; i <= 4; i++) {
        const step = document.getElementById('step' + i);
        if (step) {
            step.classList.remove('active', 'completed');
            if (i < activeStep) {
                step.classList.add('completed');
            } else if (i === activeStep) {
                step.classList.add('active');
            }
        }
    }
}

function validateRescheduleForm() {
    const treatment = document.getElementById('treatment').value;
    const date = document.getElementById('appointment_date').value;
    const doctorId = document.getElementById('selected_doctor_id').value;
    const timeSlot = document.getElementById('selected_time_slot').value;
    
    if (!treatment) {
        alert('Please select a treatment.');
        return false;
    }
    
    if (!date) {
        alert('Please select a date.');
        return false;
    }
    
    if (!doctorId) {
        alert('Please select a doctor.');
        return false;
    }
    
    if (!timeSlot) {
        alert('Please select a time slot.');
        return false;
    }
    
    return true;
}

function showRescheduleConfirmationModal() {
    const treatmentSelect = document.getElementById('treatment');
    const selectedTreatment = treatmentSelect.options[treatmentSelect.selectedIndex].text;
    const selectedDate = document.getElementById('appointment_date').value;
    const selectedDoctorId = document.getElementById('selected_doctor_id').value;
    const selectedTime = document.getElementById('selected_time_slot').value;
    const customerMessage = document.getElementById('customer_message').value;
    
    // Find doctor name
    let doctorName = 'Unknown Doctor';
    if (selectedDoctorId && window.doctorData) {
        const doctor = window.doctorData.find(d => d.id == selectedDoctorId);
        if (doctor) {
            doctorName = doctor.name;
        }
    }
    
    // Update modal content
    document.getElementById('confirm-treatment').textContent = selectedTreatment;
    document.getElementById('confirm-doctor').textContent = doctorName;
    document.getElementById('confirm-date').textContent = selectedDate;
    document.getElementById('confirm-time').textContent = selectedTime;
    document.getElementById('confirm-message').textContent = customerMessage || 'No specific concerns mentioned.';
    
    // Show modal using jQuery if available, otherwise fallback to basic show
    if (typeof $ !== 'undefined' && $.fn.modal) {
        $('#confirmationModal').modal('show');
    } else {
        // Fallback for basic modal display
        const modal = document.getElementById('confirmationModal');
        if (modal) {
            modal.style.display = 'block';
            modal.classList.add('show');
            if (document.body) {
                document.body.classList.add('modal-open');
            }
        }
    }
}

// APPOINTMENT PAGE SPECIFIC FUNCTIONS
function initializeAppointmentBooking() {
    const treatmentSelect = document.getElementById('treatment');
    const dateInput = document.getElementById('appointment_date');
    const submitBtn = document.getElementById('submit-appointment');
    const finalConfirmBtn = document.getElementById('final-confirm');
    const form = document.getElementById('appointment-form');
    
    // Setup date restrictions (readonly for both pages)
    setupDateInputRestrictions(dateInput);
    
    // Add date change event listener
    if (dateInput) {
        dateInput.addEventListener('change', function() {
            if (this.value && validateWeekday(this.value)) {
                const treatmentId = treatmentSelect ? treatmentSelect.value : null;
                if (treatmentId) {
                    generateDoctorCards(this.value, treatmentId);
                    showSection('doctor-section');
                    updateStepIndicator(3);
                }
            }
        });
    }
    
    // Step 1: Treatment selection
    if (treatmentSelect) {
        treatmentSelect.addEventListener('change', function() {
            if (this.value) {
                showSection('date-section');
                updateStepIndicator(2);
                
                // If date is already selected, load doctors immediately
                const dateValue = dateInput ? dateInput.value : null;
                if (dateValue && validateWeekday(dateValue)) {
                    generateDoctorCards(dateValue, this.value);
                    showSection('doctor-section');
                    updateStepIndicator(3);
                }
            }
        });
    }
    
    // Submit appointment button
    if (submitBtn) {
        submitBtn.addEventListener('click', function() {
            if (validateForm()) {
                showConfirmationModal();
            }
        });
    }
    
    // Final confirmation button
    if (finalConfirmBtn) {
        finalConfirmBtn.addEventListener('click', function() {
            if (form) {
                form.submit();
            }
        });
    }
    
    // Modal close handlers
    const modal = document.getElementById('confirmationModal');
    if (modal) {
        const closeButtons = modal.querySelectorAll('[data-dismiss="modal"]');
        closeButtons.forEach(function(btn) {
            btn.addEventListener('click', function() {
                modal.style.display = 'none';
                modal.classList.remove('show');
                document.body.classList.remove('modal-open');
            });
        });
    }
    
    // Initialize pre-selected treatment if available
    if (window.preSelectedTreatment) {
        setTimeout(() => {
            if (treatmentSelect) {
                treatmentSelect.value = window.preSelectedTreatment;
                treatmentSelect.dispatchEvent(new Event('change'));
            }
        }, 100);
    }
    
    // Add click handlers for step navigation
    const stepIndicators = document.querySelectorAll('.step.clickable');
    stepIndicators.forEach(function(step) {
        step.addEventListener('click', function() {
            const targetSection = this.getAttribute('data-section');
            const stepNumber = parseInt(this.id.replace('step', ''));
            
            if (targetSection && validateAppointmentStepNavigation(stepNumber)) {
                showSection(targetSection);
                updateStepIndicator(stepNumber);
            }
        });
    });
}

function validateAppointmentStepNavigation(targetStep) {
    const treatment = document.getElementById('treatment').value;
    const date = document.getElementById('appointment_date').value;
    const doctorId = document.getElementById('selected_doctor_id').value;
    const timeSlot = document.getElementById('selected_time_slot').value;
    
    // Always allow going back to step 1
    if (targetStep === 1) {
        return true;
    }
    
    // For step 2 (date), require treatment
    if (targetStep === 2) {
        if (!treatment) {
            alert('Please select a treatment first before choosing a date.');
            return false;
        }
        return true;
    }
    
    // For step 3 (doctor), check requirements in order
    if (targetStep === 3) {
        if (!treatment) {
            alert('Please select a treatment first before choosing a date.');
            return false;
        }
        if (!date) {
            alert('Please select a date first before choosing a doctor.');
            return false;
        }
        return true;
    }
    
    // For step 4 (message), check requirements in order
    if (targetStep === 4) {
        if (!treatment) {
            alert('Please select a treatment first before choosing a date.');
            return false;
        }
        if (!date) {
            alert('Please select a date first before choosing a doctor.');
            return false;
        }
        if (!doctorId || !timeSlot) {
            alert('Please select a doctor and time slot first.');
            return false;
        }
        return true;
    }
    
    return true;
}

// Global utility functions for section navigation and step indication
function showSection(sectionId) {
    console.log('showSection called with sectionId:', sectionId);
    
    // Hide all sections first
    const sections = document.querySelectorAll('.form-section');
    console.log('Found ' + sections.length + ' form sections');
    
    sections.forEach(section => {
        if (section.id !== 'treatment-section') {
            section.classList.add('hidden');
            console.log('Hidden section:', section.id);
        }
    });
    
    // Show target section
    const targetSection = document.getElementById(sectionId);
    if (targetSection) {
        targetSection.classList.remove('hidden');
        console.log('Showing section:', sectionId);
    } else {
        console.error('Target section not found:', sectionId);
    }
}

// Update step indicator
function updateStepIndicator(activeStep) {
    console.log('updateStepIndicator called with activeStep:', activeStep);
    
    for (let i = 1; i <= 4; i++) {
        const step = document.getElementById('step' + i);
        if (step) {
            step.classList.remove('active', 'completed');
            if (i < activeStep) {
                step.classList.add('completed');
                console.log('Completed step:', i);
            } else if (i === activeStep) {
                step.classList.add('active');
                console.log('Activated step:', i);
            } else {
                console.log('Deactivated step:', i);
            }
        } else {
            console.warn('Step element not found: step' + i);
        }
    }
}

// Function to load available doctors using JSP data
// AJAX function to load doctors and time slots
function generateDoctorCards(selectedDate, treatmentId) {
    const container = document.getElementById('doctor-cards-container');
    
    if (!treatmentId) {
        container.innerHTML = '<div class="alert alert-warning">Please select a treatment first</div>';
        return;
    }
    
    if (!selectedDate) {
        container.innerHTML = '<div class="alert alert-warning">Please select a date first</div>';
        return;
    }
    
    // Show loading message
    container.innerHTML = '<div class="alert alert-info"><i class="fa fa-spinner fa-spin"></i> Loading available doctors and time slots...</div>';
    
    // Use vanilla JavaScript instead of jQuery for AJAX
    const xhr = new XMLHttpRequest();
    xhr.open('GET', 'AppointmentServlet?action=getAvailableSlots&treatment_id=' + treatmentId + '&selected_date=' + selectedDate, true);
    
    xhr.onreadystatechange = function() {
        if (xhr.readyState === 4) {
            if (xhr.status === 200) {
                try {
                    const response = JSON.parse(xhr.responseText);
                    console.log('Server response:', response);
                    
                    if (response.error) {
                        container.innerHTML = '<div class="alert alert-danger">Error: ' + response.error + '</div>';
                        return;
                    }
                    
                    if (!response.doctors || response.doctors.length === 0) {
                        container.innerHTML = '<div class="alert alert-warning">No doctors available for the selected treatment on this date</div>';
                        return;
                    }
                    
                    let cardsHTML = '';
                    
                    response.doctors.forEach(function(doctor) {
                        console.log('Processing doctor:', doctor);
                        
                        cardsHTML += `
                            <div class="doctor-card" data-doctor-id="${doctor.id}">
                                <div class="doctor-info">
                                    <h5><i class="fa fa-user-md"></i> Dr. ${doctor.name || 'Unknown'}</h5>
                                    <p class="specialization">${doctor.specialization || 'General Practice'}</p>
                                </div>
                                <div class="time-slots-container">
                                    <h6>Available Time Slots:</h6>
                                    <div class="time-slots-grid">
                        `;
                        
                        if (doctor.timeSlots && doctor.timeSlots.length > 0) {
                            // Check if selected date is today
                            const selectedDateObj = new Date(selectedDate + 'T00:00:00');
                            const today = new Date();
                            today.setHours(0, 0, 0, 0);
                            selectedDateObj.setHours(0, 0, 0, 0);
                            const isToday = selectedDateObj.getTime() === today.getTime();
                            
                            doctor.timeSlots.forEach(function(slot) {
                                let isSlotAvailable = slot.available;
                                let btnClass = 'time-slot-btn';
                                let disabled = '';
                                let title = 'Click to select this time slot';
                                
                                // If it's today, check if the time slot has passed
                                if (isToday && isSlotAvailable) {
                                    const isTimeAvailable = isTimeSlotAvailableToday(slot.time);
                                    if (!isTimeAvailable) {
                                        isSlotAvailable = false;
                                        btnClass = 'time-slot-btn disabled';
                                        disabled = 'disabled';
                                        title = 'This time slot has already passed';
                                    }
                                } else if (!slot.available) {
                                    btnClass = 'time-slot-btn disabled';
                                    disabled = 'disabled';
                                    title = 'This time slot is already booked';
                                }
                                
                                cardsHTML += `
                                    <button type="button" class="${btnClass}" 
                                            data-doctor-id="${doctor.id}" 
                                            data-time="${slot.time}"
                                            data-display-time="${slot.display}"
                                            title="${title}"
                                            ${disabled}>
                                        ${slot.display}
                                    </button>
                                `;
                            });
                        } else {
                            cardsHTML += '<p class="text-muted">No available time slots for this doctor on selected date</p>';
                        }
                        
                        cardsHTML += `
                                    </div>
                                </div>
                            </div>
                        `;
                    });
                    
                    container.innerHTML = cardsHTML;
                    
                    // Add click handlers for time slot selection
                    addTimeSlotHandlers();
                    
                } catch (e) {
                    console.error('Error parsing response:', e);
                    container.innerHTML = '<div class="alert alert-danger">Error processing server response</div>';
                }
            } else {
                console.error('HTTP Error:', xhr.status);
                container.innerHTML = '<div class="alert alert-danger">Failed to load doctor availability. Please try again.</div>';
            }
        }
    };
    
    xhr.send();
}

// Add event handlers for time slot selection
function addTimeSlotHandlers() {
    console.log('Adding time slot handlers...');
    const timeSlotBtns = document.querySelectorAll('.time-slot-btn:not(.disabled)');
    console.log('Found ' + timeSlotBtns.length + ' available time slot buttons');
    
    timeSlotBtns.forEach(function(btn) {
        btn.addEventListener('click', function() {
            console.log('Time slot clicked!');
            
            // Remove previous selections
            document.querySelectorAll('.time-slot-btn').forEach(b => b.classList.remove('selected'));
            document.querySelectorAll('.doctor-card').forEach(c => c.classList.remove('selected'));
            
            // Select current time slot and doctor
            this.classList.add('selected');
            this.closest('.doctor-card').classList.add('selected');
            
            // Update hidden form fields
            const doctorId = this.getAttribute('data-doctor-id');
            const timeSlot = this.getAttribute('data-time');
            
            console.log('Setting form values - Doctor ID:', doctorId, 'Time:', timeSlot);
            
            const doctorIdField = document.getElementById('selected_doctor_id');
            const timeSlotField = document.getElementById('selected_time_slot');
            
            if (doctorIdField) {
                doctorIdField.value = doctorId;
                console.log('Doctor ID field updated:', doctorIdField.value);
            } else {
                console.error('Doctor ID field not found!');
            }
            
            if (timeSlotField) {
                timeSlotField.value = timeSlot;
                console.log('Time slot field updated:', timeSlotField.value);
            } else {
                console.error('Time slot field not found!');
            }
            
            console.log('About to show message section...');
            
            // Show message section (different for each page)
            const isReschedulePage = document.getElementById('reschedule-form') !== null;
            if (isReschedulePage) {
                showRescheduleSection('message-section');
                updateRescheduleStepIndicator(4);
            } else {
                showSection('message-section');
                updateStepIndicator(4);
            }
            
            console.log('Message section should now be visible');
        });
    });
}

// Function to validate form before submission
function validateForm() {
    const treatment = document.getElementById('treatment').value;
    const date = document.getElementById('appointment_date').value;
    const doctorId = document.getElementById('selected_doctor_id').value;
    const timeSlot = document.getElementById('selected_time_slot').value;
    
    if (!treatment) {
        alert('Please select a treatment.');
        return false;
    }
    
    if (!date) {
        alert('Please select an appointment date.');
        return false;
    }
    
    if (!doctorId) {
        alert('Please select a doctor.');
        return false;
    }
    
    if (!timeSlot) {
        alert('Please select a time slot.');
        return false;
    }
    
    return true;
}

// Function to show confirmation modal
function showConfirmationModal() {
    const treatmentSelect = document.getElementById('treatment');
    const selectedTreatment = treatmentSelect.options[treatmentSelect.selectedIndex].text;
    const selectedDate = document.getElementById('appointment_date').value;
    const selectedDoctorId = document.getElementById('selected_doctor_id').value;
    const selectedTime = document.getElementById('selected_time_slot').value;
    const customerMessage = document.getElementById('customer_message').value;
    
    // Find doctor name
    let doctorName = 'Unknown Doctor';
    if (window.doctorData) {
        const doctor = window.doctorData.find(d => d.id == selectedDoctorId);
        if (doctor) {
            doctorName = doctor.name;
        }
    }
    
    // Update modal content
    document.getElementById('confirm-treatment').textContent = selectedTreatment;
    document.getElementById('confirm-doctor').textContent = doctorName;
    document.getElementById('confirm-date').textContent = selectedDate;
    document.getElementById('confirm-time').textContent = selectedTime;
    document.getElementById('confirm-message').textContent = customerMessage || 'No specific concerns mentioned.';
    
    // Show modal
    const modal = document.getElementById('confirmationModal');
    if (modal) {
        modal.style.display = 'block';
        modal.classList.add('show');
        document.body.classList.add('modal-open');
    }
    
    function filterAppointments() {
            const status = document.getElementById('statusFilter').value;
            window.location.href = 'appointment_history.jsp?status=' + status;
        }
        
    function submitFeedback(appointmentId) {
        // Redirect to feedback page with appointment ID
        window.location.href = 'feedback.jsp?appointment_id=' + appointmentId;
        }
        
function generateReceipt(appointmentId) {
    console.log('Generating receipt for appointment ID:', appointmentId);
    
    if (!appointmentId) {
        showError('Invalid appointment ID');
        return;
    }
    
    // Show loading state
    const button = document.querySelector(`button[onclick="generateReceipt(${appointmentId})"]`);
    if (button) {
        const originalText = button.innerHTML;
        button.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Generating...';
        button.disabled = true;
        
        // Reset button after delay
        setTimeout(() => {
            button.innerHTML = originalText;
            button.disabled = false;
        }, 3000);
    }
    
    try {
        // Create URL for receipt viewing
        const receiptUrl = `SimpleReceiptServlet?action=view&appointment_id=${appointmentId}`;
        
        // Open receipt in new window/tab
        const receiptWindow = window.open(receiptUrl, '_blank', 'width=900,height=700,scrollbars=yes,resizable=yes');
        
        if (receiptWindow) {
            // Show success message
            setTimeout(() => {
                showReceiptSuccessMessage();
            }, 500);
        } else {
            // Fallback if popup is blocked - redirect current page
            window.location.href = receiptUrl;
        }
        
    } catch (error) {
        console.error('Error generating receipt:', error);
        showError('Failed to generate receipt. Please try again.');
    }
}

// Show success message after receipt generation
function showReceiptSuccessMessage() {
    const successMsg = document.createElement('div');
    successMsg.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: #28a745;
        color: white;
        padding: 15px 20px;
        border-radius: 8px;
        z-index: 10000;
        box-shadow: 0 4px 12px rgba(0,0,0,0.2);
        max-width: 300px;
    `;
    successMsg.innerHTML = `
        <i class="fa fa-check-circle" style="margin-right: 8px;"></i>
        <strong>Receipt Opened!</strong><br>
        <small>Your receipt is now available in a new window. You can print or save it as PDF.</small>
    `;
    
    document.body.appendChild(successMsg);
    
    // Auto-remove after 5 seconds
    setTimeout(() => {
        if (document.body.contains(successMsg)) {
            document.body.removeChild(successMsg);
        }
    }, 5000);
}
    
// Enhanced date formatting and validation functions for booking restrictions
function formatDateForInput(date) {
    return date.getFullYear() + '-' + 
           String(date.getMonth() + 1).padStart(2, '0') + '-' + 
           String(date.getDate()).padStart(2, '0');
}

// Generate 30-minute time slots from 9 AM to 5 PM
function generateTimeSlots() {
    const timeSlots = [];
    const startHour = 9; // 9 AM
    const endHour = 17; // 5 PM (exclusive)
    const slotDuration = 30; // 30 minutes
    
    for (let hour = startHour; hour < endHour; hour++) {
        for (let minute = 0; minute < 60; minute += slotDuration) {
            const timeString = String(hour).padStart(2, '0') + ':' + String(minute).padStart(2, '0');
            const displayTime = formatTime12Hour(hour, minute);
            timeSlots.push({
                value: timeString,
                display: displayTime
            });
        }
    }
    
    return timeSlots;
}

// Format time to 12-hour format
function formatTime12Hour(hour, minute) {
    const period = hour >= 12 ? 'PM' : 'AM';
    const displayHour = hour > 12 ? hour - 12 : (hour === 0 ? 12 : hour);
    return displayHour + ':' + String(minute).padStart(2, '0') + ' ' + period;
}

// Show error message
function showError(message) {
    const errorMsg = document.createElement('div');
    errorMsg.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: #dc3545;
        color: white;
        padding: 15px 20px;
        border-radius: 8px;
        z-index: 10000;
        box-shadow: 0 4px 12px rgba(0,0,0,0.2);
        max-width: 300px;
    `;
    errorMsg.innerHTML = `
        <i class="fa fa-exclamation-triangle" style="margin-right: 8px;"></i>
        <strong>Error!</strong><br>
        <small>${message}</small>
    `;
    
    document.body.appendChild(errorMsg);
    
    // Auto-remove after 5 seconds
    setTimeout(() => {
        if (document.body.contains(errorMsg)) {
            document.body.removeChild(errorMsg);
        }
    }, 5000);
}

// Reschedule-specific validation function
function validateRescheduleForm() {
    const treatment = document.getElementById('treatment').value;
    const date = document.getElementById('appointment_date').value;
    const doctorId = document.getElementById('selected_doctor_id').value;
    const timeSlot = document.getElementById('selected_time_slot').value;
    
    if (!treatment) {
        alert('Please select a treatment.');
        return false;
    }
    
    if (!date) {
        alert('Please select an appointment date.');
        return false;
    }
    
    if (!doctorId) {
        alert('Please select a doctor.');
        return false;
    }
    
    if (!timeSlot) {
        alert('Please select a time slot.');
        return false;
    }
    
    return true;
}

// Reschedule-specific confirmation modal
function showRescheduleConfirmationModal() {
    const treatmentSelect = document.getElementById('treatment');
    const selectedTreatment = treatmentSelect.options[treatmentSelect.selectedIndex].text;
    const selectedDate = document.getElementById('appointment_date').value;
    const selectedDoctorId = document.getElementById('selected_doctor_id').value;
    const selectedTime = document.getElementById('selected_time_slot').value;
    const customerMessage = document.getElementById('customer_message').value;
    
    // Find doctor name
    let doctorName = 'Unknown Doctor';
    if (window.doctorData) {
        const doctor = window.doctorData.find(d => d.id == selectedDoctorId);
        if (doctor) {
            doctorName = doctor.name;
        }
    }
    
    // Update modal content
    document.getElementById('confirm-treatment').textContent = selectedTreatment;
    document.getElementById('confirm-doctor').textContent = doctorName;
    document.getElementById('confirm-date').textContent = selectedDate;
    document.getElementById('confirm-time').textContent = selectedTime;
    document.getElementById('confirm-message').textContent = customerMessage || 'No specific concerns mentioned.';
    
    // Show modal
    $('#confirmationModal').modal('show');
}

// Initialize reschedule form with same structure as appointment form
function initializeRescheduleBooking() {
    const treatmentSelect = document.getElementById('treatment');
    const dateInput = document.getElementById('appointment_date');
    const submitBtn = document.getElementById('submit-reschedule');
    const finalConfirmBtn = document.getElementById('final-confirm');
    const form = document.getElementById('reschedule-form');
    
    // Set date restrictions: exactly 7 days from today (including today), weekdays only
    const today = new Date();
    const currentHour = today.getHours();
    
    // Determine minimum date based on current time
    let minDate = new Date();
    if (currentHour >= 17) {
        minDate.setDate(today.getDate() + 1);
    }
    
    // Maximum date is exactly 6 days from TODAY (making it 7 days total including today)
    const maxDate = new Date();
    maxDate.setDate(today.getDate() + 6);
    
    if (dateInput) {
        dateInput.setAttribute('min', formatDateForInput(minDate));
        dateInput.setAttribute('max', formatDateForInput(maxDate));
        
        // Prevent manual typing - only allow calendar selection
        dateInput.setAttribute('readonly', 'true');
        
        // Add change event for date selection
        dateInput.addEventListener('change', function() {
            if (this.value && validateWeekday(this.value)) {
                const treatmentId = treatmentSelect ? treatmentSelect.value : null;
                if (treatmentId) {
                    generateDoctorCards(this.value, treatmentId);
                    showSection('doctor-section');
                    updateStepIndicator(3);
                }
            }
        });
    }
    
    // Step 1: Treatment selection
    if (treatmentSelect) {
        treatmentSelect.addEventListener('change', function() {
            if (this.value) {
                showSection('date-section');
                updateStepIndicator(2);
                
                // If date is already selected, load doctors immediately
                const dateValue = dateInput ? dateInput.value : null;
                if (dateValue && validateWeekday(dateValue)) {
                    generateDoctorCards(dateValue, this.value);
                    showSection('doctor-section');
                    updateStepIndicator(3);
                }
            }
        });
    }
    
    // Submit button handler
    if (submitBtn) {
        submitBtn.addEventListener('click', function() {
            if (validateRescheduleForm()) {
                showRescheduleConfirmationModal();
            }
        });
    }
    
    // Final confirmation handler
    if (finalConfirmBtn) {
        finalConfirmBtn.addEventListener('click', function() {
            if (form) {
                form.submit();
            }
        });
    }
}
}

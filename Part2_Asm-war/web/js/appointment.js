// Dynamic Appointment Booking JavaScript
document.addEventListener('DOMContentLoaded', function() {
    initializeAppointmentBooking();
});

function initializeAppointmentBooking() {
    const treatmentSelect = document.getElementById('treatment');
    const dateInput = document.getElementById('appointment_date');
    const submitBtn = document.getElementById('submit-appointment');
    const finalConfirmBtn = document.getElementById('final-confirm');
    const form = document.getElementById('appointment-form');
    
    // Set minimum date to today
    const today = new Date().toISOString().split('T')[0];
    if (dateInput) {
        dateInput.setAttribute('min', today);
    }
    
    let selectedDoctor = null;
    let selectedTimeSlot = null;
    
    // Step 1: Treatment selection
    if (treatmentSelect) {
        treatmentSelect.addEventListener('change', function() {
            if (this.value) {
                showSection('date-section');
                updateStepIndicator(2);
            }
        });
    }
    
    // Step 2: Date selection
    if (dateInput) {
        dateInput.addEventListener('change', function() {
            if (this.value) {
                loadAvailableDoctors();
                showSection('doctor-section');
                updateStepIndicator(3);
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
    
    // Show section function
    function showSection(sectionId) {
        // Hide all sections first
        const sections = document.querySelectorAll('.form-section');
        sections.forEach(section => {
            if (section.id !== 'treatment-section') {
                section.classList.add('hidden');
            }
        });
        
        // Show target section
        const targetSection = document.getElementById(sectionId);
        if (targetSection) {
            targetSection.classList.remove('hidden');
            
            // Show message section when doctor section is shown
            if (sectionId === 'doctor-section') {
                setTimeout(() => {
                    const messageSection = document.getElementById('message-section');
                    if (messageSection) {
                        messageSection.classList.remove('hidden');
                        updateStepIndicator(4);
                    }
                }, 1000);
            }
        }
    }
    
    // Update step indicator
    function updateStepIndicator(activeStep) {
        for (let i = 1; i <= 4; i++) {
            const step = document.getElementById('step' + i);
            if (step) {
                if (i <= activeStep) {
                    step.classList.add('active');
                } else {
                    step.classList.remove('active');
                }
            }
        }
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
}

// Function to load available doctors using JSP data
window.loadAvailableDoctors = function() {
    const doctorsContainer = document.getElementById('doctor-cards-container');
    if (doctorsContainer) {
        doctorsContainer.innerHTML = '<div class="text-center"><i class="fa fa-spinner fa-spin"></i> Loading available doctors...</div>';
        
        setTimeout(() => {
            doctorsContainer.innerHTML = '';
            
            // Use the global doctorData passed from JSP
            if (window.doctorData && window.doctorData.length > 0) {
                window.doctorData.forEach(doctor => {
                    createDoctorCard(doctor.id, doctor.name, doctor.specialization);
                });
            } else {
                doctorsContainer.innerHTML = '<div class="text-center text-muted">No doctors available at the moment.</div>';
            }
        }, 500);
    }
};

// Function to create simplified doctor card
window.createDoctorCard = function(doctorId, doctorName, specialization) {
    const doctorsContainer = document.getElementById('doctor-cards-container');
    if (!doctorsContainer) return;
    
    const doctorCard = document.createElement('div');
    doctorCard.className = 'doctor-card';
    doctorCard.setAttribute('data-doctor-id', doctorId);
    
    // Generate sample time slots
    const timeSlots = ['09:00', '09:30', '10:00', '10:30', '11:00', '11:30', 
                      '14:00', '14:30', '15:00', '15:30', '16:00', '16:30'];
    
    // Randomly make some slots unavailable for demo
    const availableSlots = timeSlots.filter(() => Math.random() > 0.3);
    
    let timeSlotsHtml = '';
    timeSlots.forEach(slot => {
        const isAvailable = availableSlots.includes(slot);
        timeSlotsHtml += `<a class="time-slot ${isAvailable ? 'available' : 'unavailable'}" 
                          data-time="${slot}" ${!isAvailable ? 'style="pointer-events: none;"' : ''}>${slot}</a>`;
    });
    
    // Create simplified doctor card HTML
    doctorCard.innerHTML = `
        <div class="doctor-info-simple">
            <h5 class="doctor-name">${doctorName}</h5>
            <div class="doctor-specialization">${specialization || 'General Practice'}</div>
        </div>
        <div class="time-slots">
            ${timeSlotsHtml}
        </div>
    `;
    
    // Add click handlers for time slots
    doctorCard.addEventListener('click', function(e) {
        if (e.target.classList.contains('time-slot') && e.target.classList.contains('available')) {
            handleTimeSlotSelection(doctorId, e.target.getAttribute('data-time'), e.target, doctorCard);
        } else if (!e.target.classList.contains('time-slot')) {
            // Clicked on doctor card but not time slot - select doctor
            selectDoctor(doctorCard, doctorId);
        }
    });
    
    doctorsContainer.appendChild(doctorCard);
};

// Function to handle time slot selection
function handleTimeSlotSelection(doctorId, timeSlot, timeElement, doctorCard) {
    // Clear previous selections
    document.querySelectorAll('.time-slot.selected').forEach(el => el.classList.remove('selected'));
    document.querySelectorAll('.doctor-card.selected').forEach(el => el.classList.remove('selected'));
    
    // Select current time slot and doctor
    timeElement.classList.add('selected');
    doctorCard.classList.add('selected');
    
    // Update hidden form fields
    document.getElementById('selected_doctor_id').value = doctorId;
    document.getElementById('selected_time_slot').value = timeSlot;
    
    console.log('Selected:', {doctorId, timeSlot});
}

// Function to select doctor (when clicking on doctor info, not time slot)
function selectDoctor(doctorCard, doctorId) {
    // Clear previous doctor selections but keep time slot selections
    document.querySelectorAll('.doctor-card.selected').forEach(el => el.classList.remove('selected'));
    
    // Select current doctor
    doctorCard.classList.add('selected');
    
    // Update doctor field but don't change time slot
    document.getElementById('selected_doctor_id').value = doctorId;
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
}

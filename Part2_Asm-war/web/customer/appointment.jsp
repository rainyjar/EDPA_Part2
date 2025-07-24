<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="model.Doctor" %>
<%@ page import="model.Treatment" %>
<%@ page import="model.Customer" %>
<%
    // Check if user is logged in
    Customer loggedInCustomer = (Customer) session.getAttribute("customer");
    if (loggedInCustomer == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    // Get data from servlet
    List<Doctor> doctorList = (List<Doctor>) request.getAttribute("doctorList");
    List<Treatment> treatmentList = (List<Treatment>) request.getAttribute("treatmentList");
    
    // Get pre-selected treatment ID if coming from treatment page
    String preSelectedTreatment = request.getParameter("treatment_id");
%>

<!DOCTYPE html>
<html lang="en">

<head>
    <title>Book Appointment - APU Medical Center</title>
    <%@ include file="/includes/head.jsp" %>
</head>

<body id="top" data-spy="scroll" data-target=".navbar-collapse" data-offset="50">

    <%@ include file="/includes/preloader.jsp" %>
    <%@ include file="/includes/header.jsp" %>
    <%@ include file="/includes/navbar.jsp" %>

    <!-- APPOINTMENT SECTION -->
    <section class="appointment-container">
        <div class="container">
            <div class="row">
                <div class="col-md-8 col-md-offset-2">
                    <img src="<%= request.getContextPath() %>/images/cust_homepage/appointment-image.jpg" class="img-responsive">
                    <div class="appointment-form-wrapper">
                        
                        <!-- Error and Success Messages -->
                        <%
                            String errorParam = request.getParameter("error");
                            String successParam = request.getParameter("success");
                        %>
                        <% if (errorParam != null) { %>
                            <div class="alert alert-danger alert-dismissible" role="alert">
                                <button type="button" class="close" data-dismiss="alert">&times;</button>
                                <i class="fa fa-exclamation-circle"></i>
                                <% if ("missing_treatment".equals(errorParam)) { %>
                                    Please select a treatment.
                                <% } else if ("missing_doctor".equals(errorParam)) { %>
                                    Please select a doctor.
                                <% } else if ("missing_date".equals(errorParam)) { %>
                                    Please select an appointment date.
                                <% } else if ("missing_time".equals(errorParam)) { %>
                                    Please select an appointment time.
                                <% } else if ("invalid_selection".equals(errorParam)) { %>
                                    Invalid treatment or doctor selection. Please try again.
                                <% } else if ("invalid_date".equals(errorParam)) { %>
                                    Please select a future date for your appointment (weekdays only, within the next week).
                                <% } else if ("invalid_time".equals(errorParam)) { %>
                                    Please select a valid time slot (9:00 AM - 5:00 PM, 30-minute intervals).
                                <% } else if ("time_conflict".equals(errorParam)) { %>
                                    The selected time slot is not available. Please choose another time.
                                <% } else if ("booking_failed".equals(errorParam)) { %>
                                    Booking failed. Please try again or contact support.
                                <% } else if ("invalid_data".equals(errorParam)) { %>
                                    Invalid data provided. Please check your selections.
                                <% } else if ("invalid_datetime".equals(errorParam)) { %>
                                    Invalid date or time format. Please try again.
                                <% } else if ("load_failed".equals(errorParam)) { %>
                                    Failed to load appointment data. Please refresh the page.
                                <% } else { %>
                                    An error occurred. Please try again.
                                <% } %>
                            </div>
                        <% } %>
                        
                        <% if (successParam != null && "booked".equals(successParam)) { %>
                            <div class="alert alert-success alert-dismissible" role="alert">
                                <button type="button" class="close" data-dismiss="alert">&times;</button>
                                <i class="fa fa-check-circle"></i>
                                Appointment booked successfully! You can view it in your appointment history.
                            </div>
                        <% } %>

                        <!-- Step Indicator -->
                        <div class="step-indicator">
                            <div class="step active" id="step1">1. Select Treatment</div>
                            <div class="step" id="step2">2. Choose Date</div>
                            <div class="step" id="step3">3. Pick Doctor & Time</div>
                            <div class="step" id="step4">4. Add Message</div>
                        </div>

                        <!-- Customer Info Display -->
                        <div class="customer-info-display">
                            <h4><i class="fa fa-user"></i> Booking for:</h4>
                            <div class="row">
                                <div class="col-md-6">
                                    <p><strong>Name:</strong> <%= loggedInCustomer.getName() %></p>
                                    <p><strong>Email:</strong> <%= loggedInCustomer.getEmail() %></p>
                                </div>
                                <div class="col-md-6">
                                    <p><strong>Phone:</strong> <%= loggedInCustomer.getPhone() != null ? loggedInCustomer.getPhone() : "Not provided" %></p>
                                    <p><strong>Gender:</strong> <%= loggedInCustomer.getGender() != null ? loggedInCustomer.getGender() : "Not specified" %></p>
                                </div>
                            </div>
                        </div>

                        <!-- Appointment Form -->
                        <form id="appointment-form" method="post" action="AppointmentServlet">
                            <input type="hidden" name="action" value="book">
                            <input type="hidden" name="customer_id" value="<%= loggedInCustomer.getId() %>">
                            
                            <!-- Step 1: Treatment Selection -->
                            <div class="form-section" id="treatment-section">
                                <h4 class="section-title"><i class="fa fa-stethoscope"></i> Step 1: Select Treatment</h4>
                                <div class="form-group">
                                    <label for="treatment">Choose Treatment:</label>
                                    <select id="treatment" name="treatment_id" class="form-control" required>
                                        <option value="">Select a treatment...</option>
                                        <% if (treatmentList != null && !treatmentList.isEmpty()) {
                                            for (Treatment treatment : treatmentList) {
                                                String treatmentName = treatment.getName();
                                                if (treatmentName != null && treatmentName.contains("-")) {
                                                    treatmentName = treatmentName.substring(0, treatmentName.indexOf("-")).trim();
                                                }
                                                String selected = "";
                                                if (preSelectedTreatment != null && preSelectedTreatment.equals(String.valueOf(treatment.getId()))) {
                                                    selected = "selected";
                                                }
                                        %>
                                            <option value="<%= treatment.getId() %>" 
                                                    data-base-charge="<%= treatment.getBaseConsultationCharge() %>"
                                                    <%= selected %>>
                                                <%= treatmentName %>
                                            </option>
                                        <% 
                                            }
                                        } else { 
                                        %>
                                            <option value="" disabled>No treatments available</option>
                                        <% } %>
                                    </select>
                                </div>
                            </div>

                            <!-- Step 2: Date Selection -->
                            <div class="form-section hidden" id="date-section">
                                <h4 class="section-title"><i class="fa fa-calendar"></i> Step 2: Select Date</h4>
                                <div class="form-group">
                                    <label for="appointment_date">Choose Date (Weekdays Only):</label>
                                    <input type="date" id="appointment_date" name="appointment_date" class="form-control" required>
                                    <small class="form-text text-muted">
                                        <i class="fa fa-info-circle"></i> 
                                        Appointments are available from today until next week, Monday to Friday only.
                                    </small>
                                </div>
                            </div>

                            <!-- Step 3: Doctor & Time Selection -->
                            <div class="form-section hidden" id="doctor-section">
                                <h4 class="section-title"><i class="fa fa-user-md"></i> Step 3: Select Doctor & Time</h4>
                                <div class="form-group">
                                    <label>Available Time Slots (9:00 AM - 5:00 PM):</label>
                                    <small class="form-text text-muted" style="margin-bottom: 15px;">
                                        <i class="fa fa-clock-o"></i> 
                                        Each appointment slot is 30 minutes. Business hours: 9:00 AM to 5:00 PM, weekdays only.
                                    </small>
                                </div>
                                <div id="doctor-cards-container">
                                    <!-- Doctor cards will be populated dynamically -->
                                </div>
                                <input type="hidden" id="selected_doctor_id" name="doctor_id" required>
                                <input type="hidden" id="selected_time_slot" name="appointment_time" required>
                            </div>

                            <!-- Step 4: Message -->
                            <div class="form-section hidden" id="message-section">
                                <h4 class="section-title"><i class="fa fa-comment"></i> Step 4: Medical Concerns (Optional)</h4>
                                <div class="form-group">
                                    <label for="customer_message">Describe your medical concerns or specific requests:</label>
                                    <textarea id="customer_message" name="customer_message" class="form-control" 
                                             rows="4" placeholder="Please describe your symptoms, concerns, or any specific requests for the consultation..."></textarea>
                                    <small class="form-text text-muted">This information will help the doctor prepare for your consultation.</small>
                                </div>
                                
                                <!-- Submit Section -->
                                <div class="text-center" style="margin-top: 30px;">
                                    <button type="button" id="submit-appointment" class="btn btn-submit btn-lg">
                                        <i class="fa fa-check"></i> Book Appointment
                                    </button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Confirmation Modal -->
    <div class="modal fade" id="confirmationModal" tabindex="-1" role="dialog">
        <div class="modal-dialog modal-lg" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h4 class="modal-title"><i class="fa fa-check-circle"></i> Confirm Your Appointment</h4>
                    <button type="button" class="close" data-dismiss="modal">&times;</button>
                </div>
                <div class="modal-body">
                    <div class="row">
                        <div class="col-md-6">
                            <h5>Patient Information:</h5>
                            <p><strong>Name:</strong> <%= loggedInCustomer.getName() %></p>
                            <p><strong>Email:</strong> <%= loggedInCustomer.getEmail() %></p>
                            <p><strong>Phone:</strong> <%= loggedInCustomer.getPhone() != null ? loggedInCustomer.getPhone() : "Not provided" %></p>
                        </div>
                        <div class="col-md-6">
                            <h5>Appointment Details:</h5>
                            <p><strong>Treatment:</strong> <span id="confirm-treatment"></span></p>
                            <p><strong>Doctor:</strong> <span id="confirm-doctor"></span></p>
                            <p><strong>Date:</strong> <span id="confirm-date"></span></p>
                            <p><strong>Time:</strong> <span id="confirm-time"></span></p>
                        </div>
                    </div>
                    
                    <div style="margin-top: 15px;">
                        <h5>Medical Concerns:</h5>
                        <p id="confirm-message" style="font-style: italic; color: #666;"></p>
                    </div>
                    
                    <div class="alert alert-info">
                        <i class="fa fa-info-circle"></i>
                        <strong>Please Note:</strong> Your appointment is subject to doctor availability. 
                        Please check your appointment status for your appointment approval.
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" id="final-confirm" class="btn btn-success btn-lg">
                        <i class="fa fa-check"></i> Confirm & Book
                    </button>
                    <button type="button" class="btn btn-secondary" data-dismiss="modal">
                        <i class="fa fa-times"></i> Cancel
                    </button>
                </div>
            </div>
        </div>
    </div>

    <%@ include file="/includes/footer.jsp" %>
    <%@ include file="/includes/scripts.jsp" %>
    
    <!-- Pass JSP data to JavaScript -->
    <script>
        // Pass doctor data from JSP to JavaScript
        window.doctorData = [
            <%
            if (doctorList != null && !doctorList.isEmpty()) {
                for (int i = 0; i < doctorList.size(); i++) {
                    Doctor doctor = doctorList.get(i);
                    String doctorName = doctor.getName();
                    String specialization = doctor.getSpecialization();
                    if (doctorName != null) {
                        doctorName = doctorName.replaceAll("'", "\\\\'");
                    }
                    if (specialization == null) {
                        specialization = "";
                    } else {
                        specialization = specialization.replaceAll("'", "\\\\'");
                    }
                    if (i > 0) out.print(",");
            %>
                {
                    id: <%= doctor.getId() %>,
                    name: '<%= doctorName %>',
                    specialization: '<%= specialization %>'
                }
            <%
                }
            }
            %>
        ];
        
        // Pass pre-selected treatment info
        window.preSelectedTreatment = <%= preSelectedTreatment != null ? preSelectedTreatment : "null" %>;
        
        // Appointment booking restrictions and validation
        $(document).ready(function() {
            
            // Initialize date restrictions
            initializeDateRestrictions();
            
            // Generate time slots for appointment booking
            function generateTimeSlots() {
                const timeSlots = [];
                const startHour = 9; // 9 AM
                const endHour = 17; // 5 PM
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
            
            // Initialize date input restrictions
            function initializeDateRestrictions() {
                const dateInput = document.getElementById('appointment_date');
                const today = new Date();
                const nextWeek = new Date();
                nextWeek.setDate(today.getDate() + 7);
                
                // Set min and max dates
                dateInput.min = formatDateForInput(today);
                dateInput.max = formatDateForInput(nextWeek);
                
                // Add change event listener for weekday validation
                dateInput.addEventListener('change', function() {
                    validateSelectedDate(this.value);
                });
            }
            
            // Format date for input field (YYYY-MM-DD)
            function formatDateForInput(date) {
                return date.getFullYear() + '-' + 
                       String(date.getMonth() + 1).padStart(2, '0') + '-' + 
                       String(date.getDate()).padStart(2, '0');
            }
            
            // Validate selected date is a weekday
            function validateSelectedDate(dateValue) {
                if (!dateValue) return false;
                
                const selectedDate = new Date(dateValue + 'T00:00:00');
                const dayOfWeek = selectedDate.getDay(); // 0 = Sunday, 6 = Saturday
                
                if (dayOfWeek === 0 || dayOfWeek === 6) {
                    alert('Appointments are only available on weekdays (Monday to Friday). Please select a different date.');
                    document.getElementById('appointment_date').value = '';
                    return false;
                }
                
                return true;
            }
            
            // Enhanced doctor card generation with time slots
            function generateDoctorCards(selectedDate) {
                const container = document.getElementById('doctor-cards-container');
                const timeSlots = generateTimeSlots();
                
                if (!window.doctorData || window.doctorData.length === 0) {
                    container.innerHTML = '<div class="alert alert-warning">No doctors available</div>';
                    return;
                }
                
                let cardsHTML = '';
                
                window.doctorData.forEach(function(doctor) {
                    cardsHTML += `
                        <div class="doctor-card" data-doctor-id="${doctor.id}">
                            <div class="doctor-info">
                                <h5><i class="fa fa-user-md"></i> Dr. ${doctor.name}</h5>
                                <p class="specialization">${doctor.specialization || 'General Practice'}</p>
                            </div>
                            <div class="time-slots-container">
                                <h6>Available Time Slots:</h6>
                                <div class="time-slots-grid">
                    `;
                    
                    timeSlots.forEach(function(slot) {
                        cardsHTML += `
                            <button type="button" class="time-slot-btn" 
                                    data-doctor-id="${doctor.id}" 
                                    data-time="${slot.value}"
                                    data-display-time="${slot.display}">
                                ${slot.display}
                            </button>
                        `;
                    });
                    
                    cardsHTML += `
                                </div>
                            </div>
                        </div>
                    `;
                });
                
                container.innerHTML = cardsHTML;
                
                // Add click handlers for time slots
                addTimeSlotHandlers();
            }
            
            // Add event handlers for time slot selection
            function addTimeSlotHandlers() {
                const timeSlotBtns = document.querySelectorAll('.time-slot-btn');
                
                timeSlotBtns.forEach(function(btn) {
                    btn.addEventListener('click', function() {
                        // Remove previous selections
                        document.querySelectorAll('.time-slot-btn').forEach(b => b.classList.remove('selected'));
                        document.querySelectorAll('.doctor-card').forEach(c => c.classList.remove('selected'));
                        
                        // Add selection to clicked button and its doctor card
                        this.classList.add('selected');
                        this.closest('.doctor-card').classList.add('selected');
                        
                        // Set hidden form values
                        document.getElementById('selected_doctor_id').value = this.getAttribute('data-doctor-id');
                        document.getElementById('selected_time_slot').value = this.getAttribute('data-time');
                        
                        // Show next step
                        showNextStep('message-section');
                    });
                });
            }
            
            // Enhanced step navigation
            function showNextStep(sectionId) {
                // Hide all sections
                document.querySelectorAll('.form-section').forEach(section => {
                    section.classList.add('hidden');
                });
                
                // Show target section
                document.getElementById(sectionId).classList.remove('hidden');
                
                // Update step indicators
                updateStepIndicators(sectionId);
            }
            
            // Update step indicators
            function updateStepIndicators(currentSection) {
                const steps = document.querySelectorAll('.step');
                steps.forEach(step => step.classList.remove('active'));
                
                let stepNumber;
                switch(currentSection) {
                    case 'treatment-section': stepNumber = 1; break;
                    case 'date-section': stepNumber = 2; break;
                    case 'doctor-section': stepNumber = 3; break;
                    case 'message-section': stepNumber = 4; break;
                }
                
                for (let i = 0; i < stepNumber; i++) {
                    steps[i].classList.add('active');
                }
            }
            
            // Treatment selection handler
            document.getElementById('treatment').addEventListener('change', function() {
                if (this.value) {
                    showNextStep('date-section');
                }
            });
            
            // Date selection handler
            document.getElementById('appointment_date').addEventListener('change', function() {
                if (this.value && validateSelectedDate(this.value)) {
                    generateDoctorCards(this.value);
                    showNextStep('doctor-section');
                }
            });
            
            // Submit button handler with enhanced validation
            document.getElementById('submit-appointment').addEventListener('click', function() {
                if (validateAppointmentForm()) {
                    showConfirmationModal();
                }
            });
            
            // Enhanced form validation
            function validateAppointmentForm() {
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
                
                if (!validateSelectedDate(date)) {
                    return false;
                }
                
                if (!doctorId || !timeSlot) {
                    alert('Please select a doctor and time slot.');
                    return false;
                }
                
                return true;
            }
            
            // Show confirmation modal with appointment details
            function showConfirmationModal() {
                const treatment = document.getElementById('treatment');
                const date = document.getElementById('appointment_date').value;
                const doctorId = document.getElementById('selected_doctor_id').value;
                const timeSlot = document.getElementById('selected_time_slot').value;
                const message = document.getElementById('customer_message').value;
                
                // Find selected doctor and time display
                const selectedDoctor = window.doctorData.find(d => d.id == doctorId);
                const selectedTimeBtn = document.querySelector('.time-slot-btn.selected');
                const timeDisplay = selectedTimeBtn ? selectedTimeBtn.getAttribute('data-display-time') : timeSlot;
                
                // Format date for display
                const dateObj = new Date(date + 'T00:00:00');
                const dateDisplay = dateObj.toLocaleDateString('en-US', { 
                    weekday: 'long', 
                    year: 'numeric', 
                    month: 'long', 
                    day: 'numeric' 
                });
                
                // Populate confirmation modal
                document.getElementById('confirm-treatment').textContent = treatment.options[treatment.selectedIndex].text;
                document.getElementById('confirm-doctor').textContent = 'Dr. ' + selectedDoctor.name;
                document.getElementById('confirm-date').textContent = dateDisplay;
                document.getElementById('confirm-time').textContent = timeDisplay;
                document.getElementById('confirm-message').textContent = message || 'No specific concerns mentioned.';
                
                // Show modal
                $('#confirmationModal').modal('show');
            }
            
            // Final confirmation handler
            document.getElementById('final-confirm').addEventListener('click', function() {
                document.getElementById('appointment-form').submit();
            });
            
            // Initialize with pre-selected treatment if available
            if (window.preSelectedTreatment) {
                document.getElementById('treatment').value = window.preSelectedTreatment;
                showNextStep('date-section');
            }
        });
    </script>

</body>
</html>

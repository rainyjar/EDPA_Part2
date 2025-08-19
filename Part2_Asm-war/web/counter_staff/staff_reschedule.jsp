<%@page import="model.Appointment"%>
<%@page import="model.CounterStaff"%>
<%@page import="model.Customer"%>
<%@page import="model.Doctor"%>
<%@page import="model.Treatment"%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%
    // Check if counter staff is logged in
    CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");

    if (loggedInStaff == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // Get appointment ID from parameter
    String appointmentIdParam = request.getParameter("appointmentId");
    if (appointmentIdParam == null) {
        response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=manage&error=invalid_data");
        return;
    }

    // Get data from servlet (should be loaded by AppointmentServlet)
    List<Doctor> doctorList = (List<Doctor>) request.getAttribute("doctorList");
    List<Treatment> treatmentList = (List<Treatment>) request.getAttribute("treatmentList");
    Appointment selectedAppointment = (Appointment) request.getAttribute("selectedAppointment");
%>

<!DOCTYPE html>
<html lang="en">

    <head>
        <title>Reschedule Appointment - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/staff-appointment-booking.css">
        <link rel="stylesheet" href="${pageContext.request.contextPath}/css/user-reg-edit.css" />
        <style>
            .current-appointment {
                background: #f8f9fa;
                border: 1px solid #dee2e6;
                border-radius: 8px;
                padding: 15px;
                margin-bottom: 20px;
            }
            .appointment-detail {
                display: flex;
                align-items: center;
                margin-bottom: 8px;
            }
            .appointment-detail i {
                margin-right: 10px;
                width: 20px;
                color: #667eea;
            }
            .status-badge {
                padding: 4px 12px;
                border-radius: 20px;
                font-size: 0.85em;
                font-weight: bold;
                text-transform: uppercase;
            }
            .status-pending { background: #fff3cd; color: #856404; }
            .status-approved { background: #d4edda; color: #155724; }
            .status-overdue { background: #f5c6cb; color: #721c24; }
            .status-reschedule { background: #ffeaa7; color: #6c5502; }
            .customer-search-container {
                display: none; /* Hide customer search since we're rescheduling existing appointment */
            }
        </style>
    </head>

    <body id="top" data-spy="scroll" data-target=".navbar-collapse" data-offset="50">

        <%@ include file="/includes/header.jsp" %>
        <%@ include file="/includes/navbar.jsp" %>

        <!-- APPOINTMENT SECTION -->
        <section class="appointment-container staff-booking">
            <div class="container">
                <div class="row">
                    <a href="${pageContext.request.contextPath}/CounterStaffServletJam?action=dashboard" class="back-btn" style="margin-bottom: 30px">
                        <i class="fa fa-arrow-left"></i> Back to Dashboard
                    </a>
                    <div class="col-md-8 col-md-offset-2">
                        <img src="<%= request.getContextPath()%>/images/cust_homepage/appointment-image.jpg" class="img-responsive">
                        <div class="appointment-form-wrapper">

                            <h2 class="text-center" style="margin-bottom: 30px;">
                                <i class="fa fa-calendar"></i> Reschedule Appointment
                            </h2>

                            <!-- Current Appointment Info -->
                            <div class="current-appointment">
                                <h4><i class="fa fa-info-circle"></i> Current Appointment Details</h4>
                                <% if (selectedAppointment != null) {%>
                                <div class="appointment-detail">
                                    <i class="fa fa-id-badge"></i>
                                    <strong>Appointment ID: </strong> #<%= selectedAppointment.getId()%>
                                </div>
                                <div class="appointment-detail">
                                    <i class="fa fa-user"></i>
                                    <strong>Patient: </strong> <%= selectedAppointment.getCustomer() != null ? selectedAppointment.getCustomer().getName() : "N/A"%>
                                </div>
                                <div class="appointment-detail">
                                    <i class="fa fa-stethoscope"></i>
                                    <strong>Treatment: </strong> <%= selectedAppointment.getTreatment() != null ? selectedAppointment.getTreatment().getName() : "N/A"%>
                                </div>
                                <div class="appointment-detail">
                                    <i class="fa fa-calendar"></i>
                                    <strong>Current Appointment Date: </strong> <%= selectedAppointment.getAppointmentDate() != null ? selectedAppointment.getAppointmentDate() : "N/A"%>
                                </div>
                                <div class="appointment-detail">
                                    <i class="fa fa-clock-o"></i>
                                    <strong>Current Appointment Time: </strong> <%= selectedAppointment.getAppointmentTime() != null ? selectedAppointment.getAppointmentTime() : "N/A"%>
                                </div>
                                <div class="appointment-detail">
                                    <i class="fa fa-user-md"></i>
                                    <strong>Doctor: </strong> <%= selectedAppointment.getDoctor() != null ? "Dr. " + selectedAppointment.getDoctor().getName() : "Not Assigned"%>
                                </div>
                                <div class="appointment-detail">
                                    <i class="fa fa-info"></i>
                                    <strong>Status: </strong> <span class="status-badge status-<%= selectedAppointment.getStatus() != null ? selectedAppointment.getStatus().toLowerCase().replace(" ", "-") : "pending"%>"><%= selectedAppointment.getStatus() != null ? selectedAppointment.getStatus().toUpperCase() : "N/A"%></span>
                                </div>
                                <% } else { %>
                                <div class="alert alert-warning">
                                    <i class="fa fa-exclamation-triangle"></i>
                                    Unable to load appointment details. Please try again or contact support.
                                </div>
                                <% } %>
                            </div>

                            <!-- Error and Success Messages (Customer-style) -->
                            <%
                                String errorParam = request.getParameter("error");
                                String successParam = request.getParameter("success");
                            %>
                            <% if (errorParam != null) { %>
                            <div class="alert alert-danger alert-dismissible" role="alert">
                                <button type="button" class="close" data-dismiss="alert">&times;</button>
                                <i class="fa fa-exclamation-circle"></i>
                                <% if ("appointment_not_found".equals(errorParam)) { %>
                                Appointment not found or has been deleted.
                                <% } else if ("invalid_status".equals(errorParam)) { %>
                                This appointment cannot be rescheduled in its current status.
                                <% } else if ("invalid_data".equals(errorParam)) { %>
                                Invalid appointment data. Please try again.
                                <% } else if ("missing_treatment".equals(errorParam)) { %>
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
                                <% } else if ("overlap_conflict".equals(errorParam)) { %>
                                The selected time overlaps with another appointment. Please choose a different time.
                                <% } else if ("system_error".equals(errorParam)) { %>
                                System error occurred. Please try again later.
                                <% } else if ("not_found".equals(errorParam)) { %>
                                Appointment not found.
                                <% } else if ("unauthorized".equals(errorParam)) { %>
                                You are not authorized to reschedule this appointment.
                                <% } else if ("reschedule_failed".equals(errorParam)) { %>
                                Reschedule failed. Please try again or contact support.
                                <% } else {%>
                                An error occurred: <%= errorParam%>
                                <% } %>
                            </div>
                            <% } %>
                            <% if (successParam != null) { %>
                            <div class="alert alert-success alert-dismissible" role="alert">
                                <button type="button" class="close" data-dismiss="alert">&times;</button>
                                <i class="fa fa-check-circle"></i>
                                Appointment rescheduled successfully! The customer has been notified.
                            </div>
                            <% } %>

                            <!-- Step Indicator -->
                            <div class="step-indicator">
                                <div class="step active clickable" id="step1" data-section="treatment-section">1. Select Treatment</div>
                                <div class="step clickable" id="step2" data-section="date-section">2. Choose Date</div>
                                <div class="step clickable" id="step3" data-section="doctor-section">3. Pick Doctor & Time</div>
                                <div class="step clickable" id="step4" data-section="message-section">4. Add Message</div>
                            </div>

                            <!-- Customer Info Display -->
                            <% if (selectedAppointment != null && selectedAppointment.getCustomer() != null) {%>
                            <div class="customer-info-display" id="customer-info-display">
                                <h4><i class="fa fa-user"></i> Rescheduling for:</h4>
                                <div class="row" id="customer-details">
                                    <div class="col-md-6">
                                        <p><strong>Name:</strong> <%= selectedAppointment.getCustomer().getName()%></p>
                                        <p><strong>Email:</strong> <%= selectedAppointment.getCustomer().getEmail()%></p>
                                    </div>
                                    <div class="col-md-6">
                                        <p><strong>Phone:</strong> <%= selectedAppointment.getCustomer().getPhone() != null ? selectedAppointment.getCustomer().getPhone() : "Not provided"%></p>
                                        <p><strong>Patient ID:</strong> <%= selectedAppointment.getCustomer().getId()%></p>
                                    </div>
                                </div>
                            </div>
                            <% } else { %>
                            <div class="customer-info-display" id="customer-info-display" style="display:none;">
                                <h4><i class="fa fa-user"></i> Rescheduling for:</h4>
                                <div class="row" id="customer-details">
                                    <!-- Customer details will be populated here -->
                                </div>
                            </div>
                            <% }%>

                            <!-- Appointment Form -->
                            <form id="appointment-form" method="post" action="<%= request.getContextPath()%>/AppointmentServlet">
                                <input type="hidden" name="action" value="reschedule">
                                <input type="hidden" name="appointmentId" id="appointment_id" value="<%= appointmentIdParam%>">
                                <input type="hidden" name="customer_id" id="selected_customer_id" value="<%= selectedAppointment != null && selectedAppointment.getCustomer() != null ? selectedAppointment.getCustomer().getId() : ""%>">

                                <!-- Step 1: Treatment Selection -->
                                <div class="form-section hidden" id="treatment-section">
                                    <h4 class="section-title"><i class="fa fa-stethoscope"></i> Step 1: Select Treatment</h4>
                                    <div class="form-group">
                                        <label for="treatment">Choose Treatment:</label>
                                        <select id="treatment" name="treatment_id" class="form-control" required>
                                            <option value="" disabled selected>Select a treatment...</option>
                                            <% if (treatmentList != null && !treatmentList.isEmpty()) {
                                                    for (Treatment treatment : treatmentList) {
                                                        String treatmentName = treatment.getName();
                                                        if (treatmentName != null && treatmentName.contains("-")) {
                                                            treatmentName = treatmentName.substring(0, treatmentName.indexOf("-")).trim();
                                                        }
                                            %>
                                            <option value="<%= treatment.getId()%>">
                                                <%= treatmentName%>
                                            </option>
                                            <%
                                                }
                                            } else {
                                            %>
                                            <option value="" disabled>No treatments available</option>
                                            <% } %>
                                        </select>
                                        <small class="form-text text-muted">
                                            <i class="fa fa-info-circle"></i> 
                                            Select the treatment you need for your rescheduled appointment.
                                        </small>
                                    </div>
                                </div>

                                <!-- Step 2: Date Selection -->
                                <div class="form-section hidden" id="date-section">
                                    <h4 class="section-title"><i class="fa fa-calendar"></i> Step 2: Select New Date</h4>
                                    <div class="form-group">
                                        <label for="appointment_date">Choose Date (Weekdays Only):</label>
                                        <input type="date" id="appointment_date" name="appointment_date" class="form-control" required>
                                        <small class="form-text text-muted">
                                            <i class="fa fa-info-circle"></i> 
                                            Available: Monday to Friday, 9:00 AM - 5:00 PM.
                                            <br>Booking window: Today to 7 days ahead (weekdays only selectable).
                                            <strong>Note:</strong> If rescheduling after 5:00 PM today, earliest available date is tomorrow (if weekday).
                                        </small>
                                    </div>
                                </div>

                                <!-- Step 3: Doctor & Time Selection -->
                                <div class="form-section hidden" id="doctor-section">
                                    <h4 class="section-title"><i class="fa fa-user-md"></i> Step 3: Select Doctor & Time</h4>
                                    <div class="form-group">
                                        <label>Available Time Slots (9:00 AM - 5:00 PM):</label><br>
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
                                    <h4 class="section-title"><i class="fa fa-comment"></i> Step 4: Reschedule Reason & Notes</h4>
                                    <div class="form-group">
                                        <label for="staff_message">Reason for Reschedule:</label>
                                        <textarea id="staff_message" name="staff_message" class="form-control" 
                                                  rows="4" placeholder="Please explain why this appointment is being rescheduled..." required></textarea>
                                        <small class="form-text text-muted">This information will be recorded and may be visible to the customer.</small>
                                    </div>

                                    <!-- Submit Section -->
                                    <div class="text-center" style="margin-top: 30px;">
                                        <button type="button" id="submit-appointment" class="btn btn-submit btn-lg">
                                            <i class="fa fa-check"></i> Reschedule Appointment
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
                        <h4 class="modal-title"><i class="fa fa-check-circle"></i> Confirm Appointment Reschedule</h4>
                        <button type="button" class="close" data-dismiss="modal">&times;</button>
                    </div>
                    <div class="modal-body">
                        <div class="row">
                            <div class="col-md-6">
                                <h5>Patient Information:</h5>
                                <p><strong>Name:</strong> <span id="confirm-customer-name"></span></p>
                                <p><strong>Email:</strong> <span id="confirm-customer-email"></span></p>
                                <p><strong>Phone:</strong> <span id="confirm-customer-phone"></span></p>
                            </div>
                            <div class="col-md-6">
                                <h5>New Appointment Details:</h5>
                                <p><strong>Treatment:</strong> <span id="confirm-treatment"></span></p>
                                <p><strong>Doctor:</strong> <span id="confirm-doctor"></span></p>
                                <p><strong>Date:</strong> <span id="confirm-date"></span></p>
                                <p><strong>Time:</strong> <span id="confirm-time"></span></p>
                            </div>
                        </div>

                        <div style="margin-top: 15px;">
                            <h5>Reschedule Reason:</h5>
                            <p id="confirm-reason" style="font-style: italic; color: #666;"></p>
                        </div>

                        <div class="alert alert-info">
                            <i class="fa fa-info-circle"></i>
                            <strong>Important:</strong> This will reschedule the existing appointment. 
                            The customer will be notified of the changes.
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" id="final-confirm" class="btn btn-success btn-lg">
                            <i class="fa fa-check"></i> Confirm Reschedule
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
                            if (i > 0) {
                                out.print(",");
                            }
            %>
            {
            id: <%= doctor.getId()%>,
                name: '<%= doctorName%>',
                specialization: '<%= specialization%>'
            }
            <%
                        }
                    }
            %>
            ];

            // Store appointment ID
            window.appointmentId = '<%= appointmentIdParam%>';

            // Store selected customer data directly from JSP
            <% if (selectedAppointment != null && selectedAppointment.getCustomer() != null) {%>
            window.selectedCustomerData = {
                id: <%= selectedAppointment.getCustomer().getId()%>,
                name: '<%= selectedAppointment.getCustomer().getName().replaceAll("'", "\\\\'")%>',
                email: '<%= selectedAppointment.getCustomer().getEmail().replaceAll("'", "\\\\'")%>',
                phoneNumber: '<%= selectedAppointment.getCustomer().getPhone() != null ? selectedAppointment.getCustomer().getPhone().replaceAll("'", "\\\\'") : ""%>'
            };
            <% } else { %>
            window.selectedCustomerData = null;
            <% }%>

            // Load existing appointment data on page load
            $(document).ready(function () {
                // Since data is already loaded from JSP, just initialize the form

                // Initialize step navigation
                initializeStepNavigation();

                // Initialize date restrictions
                initializeDateRestrictions();

                // Since we're rescheduling, start from treatment selection
                showStep('treatment-section');
            });

            // Initialize step navigation (simplified version)
            function initializeStepNavigation() {
                // starts from treatment selection
                updateStepIndicators('treatment-section');
            }

            function showStep(sectionId) {
                document.querySelectorAll('.form-section').forEach(section => {
                    section.classList.add('hidden');
                });

                document.getElementById(sectionId).classList.remove('hidden');
                updateStepIndicators(sectionId);
            }

            function updateStepIndicators(currentSection) {
                const steps = document.querySelectorAll('.step');
                steps.forEach(step => {
                    step.classList.remove('active', 'completed');
                });

                let stepNumber;
                switch (currentSection) {
                    case 'treatment-section':
                        stepNumber = 0;
                        break;
                    case 'date-section':
                        stepNumber = 1;
                        break;
                    case 'doctor-section':
                        stepNumber = 2;
                        break;
                    case 'message-section':
                        stepNumber = 3;
                        break;
                }

                // Mark treatment step as completed since the first one
                if (stepNumber > 0) {
                    steps[0].classList.add('completed');
                }

                for (let i = 1; i < stepNumber; i++) {
                    steps[i].classList.add('completed');
                }
                steps[stepNumber].classList.add('active');
            }

            // Initialize date input restrictions
            function initializeDateRestrictions() {
                const dateInput = document.getElementById('appointment_date');
                const now = new Date();
                const currentHour = now.getHours();

                let minDate = new Date();
                if (currentHour >= 17) {
                    minDate.setDate(minDate.getDate() + 1);
                }

                const maxDate = new Date();
                maxDate.setDate(maxDate.getDate() + 6);

                dateInput.min = formatDateForInput(minDate);
                dateInput.max = formatDateForInput(maxDate);

                dateInput.addEventListener('change', function () {
                    if (validateSelectedDate(this.value)) {
                        const treatmentId = document.getElementById('treatment').value;
                        generateDoctorCards(this.value, treatmentId);
                        showStep('doctor-section');
                    }
                });
            }

            function formatDateForInput(date) {
                return date.getFullYear() + '-' +
                        String(date.getMonth() + 1).padStart(2, '0') + '-' +
                        String(date.getDate()).padStart(2, '0');
            }

            function validateSelectedDate(dateValue) {
                if (!dateValue)
                    return false;

                const selectedDate = new Date(dateValue + 'T00:00:00');
                const dayOfWeek = selectedDate.getDay();
                const now = new Date();
                const today = new Date();
                today.setHours(0, 0, 0, 0);
                selectedDate.setHours(0, 0, 0, 0);

                if (dayOfWeek === 0 || dayOfWeek === 6) {
                    alert('Appointments are only available on weekdays (Monday to Friday).');
                    document.getElementById('appointment_date').value = '';
                    return false;
                }

                if (selectedDate.getTime() < today.getTime()) {
                    alert('Cannot select a past date.');
                    document.getElementById('appointment_date').value = '';
                    return false;
                }

                return true;
            }

            // Treatment selection handler
            document.getElementById('treatment').addEventListener('change', function () {
                if (this.value) {
                    showStep('date-section');
                }
            });

            // Generate doctor cards and time slots
            function generateDoctorCards(selectedDate, treatmentId) {
                $('#doctor-cards-container').html('<div class="text-center"><i class="fa fa-spinner fa-spin"></i> Loading available doctors and time slots...</div>');

                $.ajax({
                    url: '<%= request.getContextPath()%>/AppointmentServlet',
                    method: 'GET',
                    data: {
                        action: 'getAvailableSlots',
                        treatment_id: treatmentId,
                        selected_date: selectedDate
                    },
                    success: function (data) {
                        displayDoctorCards(data.doctors);
                    },
                    error: function (xhr, status, error) {
                        $('#doctor-cards-container').html('<div class="alert alert-danger">Unable to load doctor availability. Please try again.</div>');
                    }
                });
            }

            function displayDoctorCards(doctors) {
                const container = $('#doctor-cards-container');
                container.empty();

                if (doctors && doctors.length > 0) {
                    doctors.forEach(function (doctor) {
                        const doctorCard = $('<div class="doctor-card">');
                        const doctorInfo = $('<div class="doctor-info">');
                        doctorInfo.append('<h5><i class="fa fa-user-md"></i> Dr. ' + doctor.name + '</h5>');
                        doctorInfo.append('<div class="specialization">' + doctor.specialization + '</div>');
                        doctorInfo.append('<h6>Available Time Slots:</h6>');

                        const timeSlotsGrid = $('<div class="time-slots-grid">');
                        doctor.timeSlots.forEach(function (slot) {
                            const btnClass = slot.available ? 'btn-outline-primary' : 'btn-secondary';
                            const disabled = slot.available ? '' : 'disabled';

                            const slotBtn = $('<button type="button" class="btn ' + btnClass + ' time-slot-btn" ' + disabled + '>')
                                    .text(slot.display)
                                    .attr('data-doctor-id', doctor.id)
                                    .attr('data-time', slot.time)
                                    .attr('data-display-time', slot.display)
                                    .click(function () {
                                        if (slot.available) {
                                            selectTimeSlot($(this));
                                        }
                                    });
                            timeSlotsGrid.append(slotBtn);
                        });

                        doctorCard.append(doctorInfo);
                        doctorCard.append(timeSlotsGrid);
                        container.append(doctorCard);
                    });
                } else {
                    container.append('<div class="alert alert-warning">No available time slots for the selected date.</div>');
                }
            }

            function selectTimeSlot(btn) {
                $('.time-slot-btn').removeClass('btn-primary').addClass('btn-outline-primary');
                $('.doctor-card').removeClass('selected');

                btn.removeClass('btn-outline-primary').addClass('btn-primary');
                btn.closest('.doctor-card').addClass('selected');

                $('#selected_doctor_id').val(btn.data('doctor-id'));
                $('#selected_time_slot').val(btn.data('time'));

                showStep('message-section');
            }

            // Submit button handler
            document.getElementById('submit-appointment').addEventListener('click', function () {
                if (validateRescheduleForm()) {
                    showConfirmationModal();
                }
            });

            function validateRescheduleForm() {
                const treatment = document.getElementById('treatment').value;
                const date = document.getElementById('appointment_date').value;
                const doctorId = document.getElementById('selected_doctor_id').value;
                const timeSlot = document.getElementById('selected_time_slot').value;
                const reason = document.getElementById('staff_message').value;

                if (!treatment) {
                    alert('Please select a treatment.');
                    return false;
                }

                if (!date) {
                    alert('Please select an appointment date.');
                    return false;
                }

                if (!doctorId || !timeSlot) {
                    alert('Please select a doctor and time slot.');
                    return false;
                }

                return true;
            }

            function showConfirmationModal() {
                const treatment = document.getElementById('treatment');
                const date = document.getElementById('appointment_date').value;
                const doctorId = document.getElementById('selected_doctor_id').value;
                const timeSlot = document.getElementById('selected_time_slot').value;
                const reason = document.getElementById('staff_message').value;

                const selectedDoctor = window.doctorData.find(d => d.id == doctorId);
                const selectedTimeBtn = document.querySelector('.time-slot-btn.selected, .time-slot-btn.btn-primary');
                const timeDisplay = selectedTimeBtn ? selectedTimeBtn.getAttribute('data-display-time') : timeSlot;

                const dateObj = new Date(date + 'T00:00:00');
                const dateDisplay = dateObj.toLocaleDateString('en-US', {
                    weekday: 'long',
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric'
                });

                // Populate customer info in modal
                if (window.selectedCustomerData) {
                    document.getElementById('confirm-customer-name').textContent = window.selectedCustomerData.name;
                    document.getElementById('confirm-customer-email').textContent = window.selectedCustomerData.email;
                    document.getElementById('confirm-customer-phone').textContent = window.selectedCustomerData.phoneNumber || window.selectedCustomerData.phone || 'Not provided';
                }

                // Populate appointment details
                document.getElementById('confirm-treatment').textContent = treatment.options[treatment.selectedIndex].text;
                document.getElementById('confirm-doctor').textContent = 'Dr. ' + selectedDoctor.name;
                document.getElementById('confirm-date').textContent = dateDisplay;
                document.getElementById('confirm-time').textContent = timeDisplay;
                document.getElementById('confirm-reason').textContent = reason;

                $('#confirmationModal').modal('show');
            }

            // Add this function to check if a time slot has passed
            function hasTimeSlotPassed(date, timeString) {
                const now = new Date();
                const [hours, minutes] = timeString.split(':').map(Number);

                const selectedDate = new Date(date);
                selectedDate.setHours(hours, minutes, 0, 0);

                return now > selectedDate;
            }

            // Update the displayDoctorCards function
            function displayDoctorCards(doctors) {
                const container = $('#doctor-cards-container');
                container.empty();

                const selectedDate = document.getElementById('appointment_date').value;
                const isToday = new Date(selectedDate).toDateString() === new Date().toDateString();

                if (doctors && doctors.length > 0) {
                    doctors.forEach(function (doctor) {
                        const doctorCard = $('<div class="doctor-card">');
                        const doctorInfo = $('<div class="doctor-info">');
                        doctorInfo.append('<h5>Dr. ' + doctor.name + '</h5>');
                        doctorInfo.append('<div class="specialization">' + doctor.specialization + '</div>');

                        const timeSlotsGrid = $('<div class="time-slots-grid">');
                        doctor.timeSlots.forEach(function (slot) {
                            // Check if time slot has passed (if today)
                            const isPastTimeSlot = isToday && hasTimeSlotPassed(selectedDate, slot.time);

                            // Determine button class and disabled status
                            let btnClass = 'btn-outline-primary';
                            let disabled = '';
                            let tooltipText = '';

                            if (isPastTimeSlot) {
                                btnClass = 'btn-secondary';
                                disabled = 'disabled';
                                tooltipText = 'This time slot has already passed';
                            } else if (!slot.available) {
                                btnClass = 'btn-secondary';
                                disabled = 'disabled';
                                tooltipText = 'This time slot is already booked';
                            }

                            const slotBtn = $('<button type="button" class="btn ' + btnClass + ' time-slot-btn" ' + disabled + '>')
                                    .text(slot.display)
                                    .attr('data-doctor-id', doctor.id)
                                    .attr('data-time', slot.time)
                                    .attr('data-display-time', slot.display);

                            // Add tooltip for disabled slots
                            if (disabled) {
                                slotBtn.attr('data-toggle', 'tooltip');
                                slotBtn.attr('data-placement', 'top');
                                slotBtn.attr('title', tooltipText);
                            }

                            slotBtn.click(function () {
                                if (slot.available && !isPastTimeSlot) {
                                    selectTimeSlot($(this));
                                }
                            });

                            timeSlotsGrid.append(slotBtn);
                        });

                        doctorCard.append(doctorInfo);
                        doctorCard.append(timeSlotsGrid);
                        container.append(doctorCard);
                    });

                    // Initialize tooltips
                    $('[data-toggle="tooltip"]').tooltip();
                } else {
                    container.append('<div class="alert alert-warning">No available time slots for the selected date.</div>');
                }
            }

            // Final confirmation handler
            document.getElementById('final-confirm').addEventListener('click', function () {
                document.getElementById('appointment-form').submit();
            });
        </script>

    </body>
</html>

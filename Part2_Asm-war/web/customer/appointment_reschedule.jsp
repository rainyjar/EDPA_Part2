<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="model.Doctor" %>
<%@ page import="model.Treatment" %>
<%@ page import="model.Customer" %>
<%@ page import="model.Appointment" %>
<%
    // Check if user is logged in
    Customer loggedInCustomer = (Customer) session.getAttribute("customer");
    if (loggedInCustomer == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    // Get appointment ID from parameter
    String appointmentIdParam = request.getParameter("id");
    if (appointmentIdParam == null || appointmentIdParam.trim().isEmpty()) {
        response.sendRedirect("appointment_history.jsp");
        return;
    }
    
    // Get data from servlet
    List<Doctor> doctorList = (List<Doctor>) request.getAttribute("doctorList");
    List<Treatment> treatmentList = (List<Treatment>) request.getAttribute("treatmentList");
    Appointment existingAppointment = (Appointment) request.getAttribute("existingAppointment");
    
    // If appointment data not loaded, redirect back
    if (existingAppointment == null) {
        response.sendRedirect("appointment_history.jsp");
        return;
    }
    
    // Validate that appointment belongs to logged in customer and is reschedable
    if (existingAppointment.getCustomer() == null || 
        existingAppointment.getCustomer().getId() != loggedInCustomer.getId() || 
        (!("pending".equals(existingAppointment.getStatus()) || "approved".equals(existingAppointment.getStatus())))) {
        response.sendRedirect("appointment_history.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html lang="en">

<head>
    <title>Reschedule Appointment - APU Medical Center</title>
    <%@ include file="/includes/head.jsp" %>
</head>

<body id="top" data-spy="scroll" data-target=".navbar-collapse" data-offset="50">

    <%@ include file="/includes/preloader.jsp" %>
    <%@ include file="/includes/header.jsp" %>
    <%@ include file="/includes/navbar.jsp" %>

    <%
    String errorMsg = request.getParameter("error");
    String successMsg = request.getParameter("success");
    %>

    <!-- Error Messages -->
    <% if (errorMsg != null) { %>
    <div class="alert alert-danger alert-dismissible" style="margin: 20px; position: fixed; top: 80px; right: 20px; z-index: 1000; width: 350px;">
        <button type="button" class="close" data-dismiss="alert">&times;</button>
        <strong>Error!</strong> 
        <% if ("invalid_id".equals(errorMsg)) { %>
            Invalid appointment ID provided.
        <% } else if ("invalid_data".equals(errorMsg)) { %>
            Invalid data provided. Please check your inputs.
        <% } else if ("invalid_date".equals(errorMsg)) { %>
            Invalid date format. Please select a valid date.
        <% } else if ("invalid_time".equals(errorMsg)) { %>
            Invalid time format. Please select a valid time.
        <% } else if ("invalid_datetime".equals(errorMsg)) { %>
            Invalid date or time format. Please check your selections.
        <% } else if ("system_error".equals(errorMsg)) { %>
            A system error occurred. Please try again.
        <% } %>
    </div>
    <% } %>

    <!-- APPOINTMENT RESCHEDULE SECTION -->
    <section class="appointment-container">
        <div class="container">
            <div class="row">
                <div class="col-md-8 col-md-offset-2">
                    <img src="<%= request.getContextPath() %>/images/cust_homepage/appointment-image.jpg" class="img-responsive">
                    <div class="appointment-form-wrapper">
                        
                        <!-- Reschedule Header -->
                        <div class="reschedule-header" style="text-align: center; margin-bottom: 30px; padding: 20px; background: #f8f9fa; border-radius: 5px;">
                            <h3 style="color: #007bff; margin: 0;">
                                <i class="fa fa-calendar"></i> Reschedule Appointment #<%= existingAppointment.getId() %>
                            </h3>
                            <p style="margin: 10px 0 0 0; color: #666;">
                                Current Status: <span class="status-badge status-<%= existingAppointment.getStatus() %>"><%= existingAppointment.getStatus().toUpperCase() %></span>
                            </p>
                        </div>
                        
                        <!-- Step Indicator -->
                        <div class="step-indicator">
                            <div class="step active" id="step1">1. Select Treatment</div>
                            <div class="step" id="step2">2. Choose Date</div>
                            <div class="step" id="step3">3. Pick Doctor & Time</div>
                            <div class="step" id="step4">4. Add Message</div>
                        </div>

                        <!-- Customer Info Display -->
                        <div class="customer-info-display">
                            <h4><i class="fa fa-user"></i> Rescheduling for:</h4>
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

                        <!-- Reschedule Form -->
                        <form id="reschedule-form" method="post" action="AppointmentServlet">
                            <input type="hidden" name="action" value="reschedule">
                            <input type="hidden" name="appointmentId" value="<%= existingAppointment.getId() %>">
                            <input type="hidden" name="customer_id" value="<%= loggedInCustomer.getId() %>">
                            <input type="hidden" name="originalStatus" value="<%= existingAppointment.getStatus() %>">
                            
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
                                                if (existingAppointment.getId() == treatment.getId()) {
                                                    selected = "selected";
                                                }
                                        %>
                                            <option value="<%= treatment.getId() %>" 
                                                    data-base-charge="<%= treatment.getBaseConsultationCharge() %>"
                                                    <%= selected %>>
                                                <%= treatmentName %>
                                                <% if (treatment.getBaseConsultationCharge() > 0) { %>
                                                    - RM <%= String.format("%.2f", treatment.getBaseConsultationCharge()) %>
                                                <% } %>
                                            </option>
                                        <% 
                                            }
                                        } else { 
                                        %>
                                            <option value="">No treatments available</option>
                                        <% } %>
                                    </select>
                                    <small class="form-text text-muted">
                                        <i class="fa fa-info-circle"></i> Select the treatment you need for this appointment
                                    </small>
                                </div>
                            </div>

                            <!-- Step 2: Date Selection -->
                            <div class="form-section" id="date-section" style="display: none;">
                                <h4 class="section-title"><i class="fa fa-calendar"></i> Step 2: Choose Date</h4>
                                <div class="form-group">
                                    <label for="appointment_date">Select Date:</label>
                                    <input type="date" id="appointment_date" name="appointment_date" 
                                           class="form-control" value="<%= existingAppointment.getAppointmentDate() != null ? existingAppointment.getAppointmentDate() : "" %>" required>
                                    <small class="form-text text-muted">
                                        <i class="fa fa-info-circle"></i> Please select a date for your appointment (minimum 1 day from today)
                                    </small>
                                </div>
                            </div>

                            <!-- Step 3: Doctor and Time Selection -->
                            <div class="form-section" id="doctor-time-section" style="display: none;">
                                <h4 class="section-title"><i class="fa fa-user-md"></i> Step 3: Pick Doctor & Time</h4>
                                
                                <!-- Doctor Selection -->
                                <div class="form-group">
                                    <label for="doctor">Choose Doctor:</label>
                                    <select id="doctor" name="doctor_id" class="form-control" required>
                                        <option value="">Select a doctor...</option>
                                        <% if (doctorList != null && !doctorList.isEmpty()) {
                                            for (Doctor doctor : doctorList) {
                                                String doctorName = doctor.getName();
                                                String specialization = doctor.getSpecialization();
                                                if (doctorName != null) {
                                                    String selected = "";
                                                    if (existingAppointment.getId() == doctor.getId()) {
                                                        selected = "selected";
                                                    }
                                        %>
                                            <option value="<%= doctor.getId() %>" <%= selected %>>
                                                <%= doctorName %>
                                                <% if (specialization != null && !specialization.trim().isEmpty()) { %>
                                                    - <%= specialization %>
                                                <% } %>
                                            </option>
                                        <%
                                                }
                                            }
                                        } else {
                                        %>
                                            <option value="">No doctors available</option>
                                        <% } %>
                                    </select>
                                    <small class="form-text text-muted">
                                        <i class="fa fa-info-circle"></i> Select your preferred doctor
                                    </small>
                                </div>

                                <!-- Time Selection -->
                                <div class="form-group">
                                    <label for="appointment_time">Select Time:</label>
                                    <select id="appointment_time" name="appointment_time" class="form-control" required>
                                        <option value="">Select time slot...</option>
                                        <option value="09:00" <%= "09:00".equals(existingAppointment.getAppointmentTime()) ? "selected" : "" %>>09:00 AM</option>
                                        <option value="09:30" <%= "09:30".equals(existingAppointment.getAppointmentTime()) ? "selected" : "" %>>09:30 AM</option>
                                        <option value="10:00" <%= "10:00".equals(existingAppointment.getAppointmentTime()) ? "selected" : "" %>>10:00 AM</option>
                                        <option value="10:30" <%= "10:30".equals(existingAppointment.getAppointmentTime()) ? "selected" : "" %>>10:30 AM</option>
                                        <option value="11:00" <%= "11:00".equals(existingAppointment.getAppointmentTime()) ? "selected" : "" %>>11:00 AM</option>
                                        <option value="11:30" <%= "11:30".equals(existingAppointment.getAppointmentTime()) ? "selected" : "" %>>11:30 AM</option>
                                        <option value="14:00" <%= "14:00".equals(existingAppointment.getAppointmentTime()) ? "selected" : "" %>>02:00 PM</option>
                                        <option value="14:30" <%= "14:30".equals(existingAppointment.getAppointmentTime()) ? "selected" : "" %>>02:30 PM</option>
                                        <option value="15:00" <%= "15:00".equals(existingAppointment.getAppointmentTime()) ? "selected" : "" %>>03:00 PM</option>
                                        <option value="15:30" <%= "15:30".equals(existingAppointment.getAppointmentTime()) ? "selected" : "" %>>03:30 PM</option>
                                        <option value="16:00" <%= "16:00".equals(existingAppointment.getAppointmentTime()) ? "selected" : "" %>>04:00 PM</option>
                                        <option value="16:30" <%= "16:30".equals(existingAppointment.getAppointmentTime()) ? "selected" : "" %>>04:30 PM</option>
                                    </select>
                                    <small class="form-text text-muted">
                                        <i class="fa fa-info-circle"></i> Choose your preferred time slot
                                    </small>
                                </div>
                            </div>

                            <!-- Step 4: Message -->
                            <div class="form-section" id="message-section" style="display: none;">
                                <h4 class="section-title"><i class="fa fa-comment"></i> Step 4: Add Message (Optional)</h4>
                                <div class="form-group">
                                    <label for="message">Additional Message:</label>
                                    <textarea id="message" name="message" class="form-control" rows="4" 
                                              placeholder="Please describe your symptoms or any special requirements..."><%= existingAppointment.getCustMessage() != null ? existingAppointment.getCustMessage() : "" %></textarea>
                                    <small class="form-text text-muted">
                                        <i class="fa fa-info-circle"></i> Optional: Add any additional information for the doctor
                                    </small>
                                </div>
                            </div>

                            <!-- Navigation Buttons -->
                            <div class="form-navigation">
                                <button type="button" id="prev-btn" class="btn btn-secondary" style="display: none;">
                                    <i class="fa fa-arrow-left"></i> Previous
                                </button>
                                <button type="button" id="next-btn" class="btn btn-primary">
                                    Next <i class="fa fa-arrow-right"></i>
                                </button>
                                <button type="button" id="review-btn" class="btn btn-info" style="display: none;">
                                    <i class="fa fa-eye"></i> Review Reschedule
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Confirmation Modal -->
    <div class="modal fade" id="confirmationModal" tabindex="-1" role="dialog">
        <div class="modal-dialog" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h4 class="modal-title">
                        <i class="fa fa-calendar"></i> Confirm Reschedule
                    </h4>
                    <button type="button" class="close" data-dismiss="modal">
                        <span>&times;</span>
                    </button>
                </div>
                <div class="modal-body">
                    <h5><strong>Rescheduling Details:</strong></h5>
                    <div id="confirmation-details"></div>
                    <hr>
                    <div class="alert alert-info">
                        <i class="fa fa-info-circle"></i>
                        <strong>Please Note:</strong> 
                        <% if ("approved".equals(existingAppointment.getStatus())) { %>
                            Since this appointment was already approved, rescheduling will change the status back to "pending" and require new approval from counter staff.
                        <% } else { %>
                            Your rescheduled appointment will remain in "pending" status and require approval from counter staff.
                        <% } %>
                        You will receive a confirmation email shortly after rescheduling.
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
        
        // Mark this as reschedule mode
        window.isRescheduleMode = true;
        window.originalAppointmentId = <%= existingAppointment.getId() %>;
        window.originalStatus = '<%= existingAppointment.getStatus() %>';
    </script>

    <!-- Reschedule-specific JavaScript -->
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // Initialize reschedule form with appointment.js logic
            if (typeof initAppointmentForm === 'function') {
                initAppointmentForm();
            }
            
            // Override final confirmation button text and behavior
            const finalConfirmBtn = document.getElementById('final-confirm');
            if (finalConfirmBtn) {
                // Update button text to reflect reschedule action
                finalConfirmBtn.innerHTML = '<i class="fa fa-check"></i> Confirm Reschedule';
                
                // Override the form submission
                finalConfirmBtn.addEventListener('click', function(e) {
                    e.preventDefault();
                    
                    // Submit the reschedule form
                    const form = document.getElementById('reschedule-form');
                    if (form) {
                        form.submit();
                    }
                });
            }
            
            // Show success message if redirected from successful reschedule
            const urlParams = new URLSearchParams(window.location.search);
            if (urlParams.get('success') === 'true') {
                alert('Appointment rescheduled successfully! Please check your appointment history for the updated details.');
                // Redirect to appointment history after showing message
                setTimeout(function() {
                    window.location.href = 'appointment_history.jsp';
                }, 2000);
            }
        });
    </script>

</body>
</html>

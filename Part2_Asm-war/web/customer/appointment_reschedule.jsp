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
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    // Get appointment ID from parameter
    String appointmentIdParam = request.getParameter("id");
    if (appointmentIdParam == null || appointmentIdParam.trim().isEmpty()) {
        response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=history&error=invalid_id");
        return;
    }
    
    // Get data from servlet
    List<Doctor> doctorList = (List<Doctor>) request.getAttribute("doctorList");
    List<Treatment> treatmentList = (List<Treatment>) request.getAttribute("treatmentList");
    Appointment existingAppointment = (Appointment) request.getAttribute("existingAppointment");
    
    // If appointment data not loaded, redirect back
    if (existingAppointment == null) {
        response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=history&error=not_found");
        return;
    }
    
    // Validate that appointment belongs to logged in customer and is reschedule-able
    if (existingAppointment.getCustomer() == null || 
        existingAppointment.getCustomer().getId() != loggedInCustomer.getId() || 
        (!("pending".equals(existingAppointment.getStatus()) || "approved".equals(existingAppointment.getStatus())))) {
        response.sendRedirect(request.getContextPath() + "/AppointmentServlet?action=history&error=cannot_reschedule");
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

    <!-- APPOINTMENT RESCHEDULE SECTION -->
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
                                <% if ("invalid_date".equals(errorParam)) { %>
                                    Please select a future date for your appointment (weekdays only, within the next week).
                                <% } else if ("invalid_time".equals(errorParam)) { %>
                                    Please select a valid time slot (9:00 AM - 5:00 PM, 30-minute intervals).
                                <% } else if ("time_conflict".equals(errorParam)) { %>
                                    The selected time slot is not available. Please choose another time.
                                <% } else if ("reschedule_failed".equals(errorParam)) { %>
                                    Rescheduling failed. Please try again or contact support.
                                <% } else if ("invalid_data".equals(errorParam)) { %>
                                    Invalid data provided. Please check your selections.
                                <% } else if ("invalid_datetime".equals(errorParam)) { %>
                                    Invalid date or time format. Please try again.
                                <% } else if ("system_error".equals(errorParam)) { %>
                                    A system error occurred. Please try again.
                                <% } else { %>
                                    An error occurred. Please try again.
                                <% } %>
                            </div>
                        <% } %>

                        <!-- Reschedule Header -->
                        <div class="reschedule-header" style="text-align: center; margin-bottom: 30px; padding: 20px; background: #f8f9fa; border-radius: 8px; border-left: 4px solid #007bff;">
                            <h3 style="color: #007bff; margin: 0; font-weight: 600;">
                                <i class="fa fa-calendar-o"></i> Reschedule Appointment #<%= existingAppointment.getId() %>
                            </h3>
                            <p style="margin: 10px 0 0 0; color: #666;">
                                Current Status: <span class="status-badge status-<%= existingAppointment.getStatus() %>"><%= existingAppointment.getStatus().toUpperCase() %></span>
                            </p>
                        </div>

                        <!-- Current Appointment Info -->
                        <div class="current-appointment-info" style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 30px; border: 1px solid #dee2e6;">
                            <h4 style="color: #495057; margin-bottom: 15px;">
                                <i class="fa fa-info-circle"></i> Current Appointment Details
                            </h4>
                            <div class="row">
                                <div class="col-md-6">
                                    <p><strong>Treatment:</strong> <%= existingAppointment.getTreatment() != null ? existingAppointment.getTreatment().getName() : "Not specified" %></p>
                                    <p><strong>Doctor:</strong> <%= existingAppointment.getDoctor() != null ? existingAppointment.getDoctor().getName() : "Not assigned" %></p>
                                </div>
                                <div class="col-md-6">
                                    <p><strong>Date:</strong> <%= existingAppointment.getAppointmentDate() != null ? existingAppointment.getAppointmentDate() : "Not set" %></p>
                                    <p><strong>Time:</strong> <%= existingAppointment.getAppointmentTime() != null ? existingAppointment.getAppointmentTime() : "Not set" %></p>
                                </div>
                            </div>
                            <% if (existingAppointment.getCustMessage() != null && !existingAppointment.getCustMessage().trim().isEmpty()) { %>
                            <p><strong>Your Message:</strong> "<%= existingAppointment.getCustMessage() %>"</p>
                            <% } %>
                        </div>

                        <!-- Step Indicator -->
                        <div class="step-indicator">
                            <div class="step active clickable" id="step1" data-section="treatment-section">1. Select Treatment</div>
                            <div class="step clickable" id="step2" data-section="date-section">2. Choose Date</div>
                            <div class="step clickable" id="step3" data-section="doctor-section">3. Pick Doctor & Time</div>
                            <div class="step clickable" id="step4" data-section="message-section">4. Update Message</div>
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
                            <input type="hidden" name="originalStatus" value="<%= existingAppointment.getStatus() %>">
                            
                            <!-- Step 1: Treatment Selection -->
                            <div class="form-section" id="treatment-section">
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
                                            <option value="<%= treatment.getId() %>" 
                                                    data-base-charge="<%= treatment.getBaseConsultationCharge() %>">
                                                <%= treatmentName %>
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
                            <div class="form-section" id="date-section" style="display: none;">
                                <h4 class="section-title"><i class="fa fa-calendar"></i> Step 2: Select New Date</h4>
                                <div class="form-group">
                                    <label for="appointment_date">Choose Date (Weekdays Only):</label>
                                    <input type="date" id="appointment_date" name="appointment_date" class="form-control" required>
                                    <small class="form-text text-muted">
                                        <i class="fa fa-info-circle"></i> 
                                        Available: Monday to Friday, 9:00 AM - 5:00 PM. 
                                        <br>Booking window: Today to 7 days ahead (weekdays only selectable). <br>
                                        <strong>Note:</strong> If rescheduling after 5:00 PM today, earliest available date is tomorrow (if weekday).
                                    </small>
                                </div>
                            </div>

                            <!-- Step 3: Doctor & Time Selection -->
                            <div class="form-section" id="doctor-section" style="display: none;">
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
                            <div class="form-section" id="message-section" style="display: none;">
                                <h4 class="section-title"><i class="fa fa-comment"></i> Step 4: Update Medical Concerns (Optional)</h4>
                                <div class="form-group">
                                    <label for="customer_message">Describe your medical concerns or specific requests:</label>
                                    <textarea id="customer_message" name="customer_message" class="form-control" 
                                             rows="4" placeholder="Please describe your symptoms, concerns, or any specific requests for the consultation..."><%= existingAppointment.getCustMessage() != null ? existingAppointment.getCustMessage() : "" %></textarea>
                                    <small class="form-text text-muted">This information will help the doctor prepare for your consultation.</small>
                                </div>
                                
                                <!-- Submit Section -->
                                <div class="text-center" style="margin-top: 30px;">
                                    <button type="button" id="submit-reschedule" class="btn btn-submit btn-lg">
                                        <i class="fa fa-check"></i> Reschedule Appointment
                                    </button>
                                    <a href="<%= request.getContextPath() %>/AppointmentServlet?action=history" class="btn btn-secondary btn-lg" style="margin-left: 10px;">
                                        <i class="fa fa-times"></i> Cancel
                                    </a>
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
                            <p><strong>Name:</strong> <%= loggedInCustomer.getName() %></p>
                            <p><strong>Email:</strong> <%= loggedInCustomer.getEmail() %></p>
                            <p><strong>Phone:</strong> <%= loggedInCustomer.getPhone() != null ? loggedInCustomer.getPhone() : "Not provided" %></p>
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
                        <h5>Medical Concerns:</h5>
                        <p id="confirm-message" style="font-style: italic; color: #666;"></p>
                    </div>
                    
                    <div class="alert alert-warning">
                        <i class="fa fa-exclamation-triangle"></i>
                        <strong>Important:</strong> Rescheduling will update your appointment details. 
                        <% if ("approved".equals(existingAppointment.getStatus())) { %>
                        Since your appointment was previously approved, it will be set back to "pending" status for new approval.
                        <% } else { %>
                        Your appointment will remain in "pending" status for approval.
                        <% } %>
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
    
    <!-- Custom styles for appointment reschedule -->
    <style>
        .step-indicator .step.clickable {
            cursor: pointer;
            transition: all 0.3s ease;
        }
        
        .step-indicator .step.clickable:hover {
            background-color: #e8f4fd;
            transform: translateY(-2px);
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        
        .step-indicator .step.completed {
            background-color: #5cb85c;
            color: white;
        }
        
        .step-indicator .step.completed:hover {
            background-color: #449d44;
        }
        
        .step-indicator .step.active {
            background-color: #337ab7;
            color: white;
        }
        
        .step-indicator .step.active:hover {
            background-color: #286090;
        }
        
        .step-indicator .step {
            border-radius: 5px;
            padding: 10px 15px;
            margin: 5px;
            border: 2px solid #ddd;
            background-color: #f8f9fa;
            color: #666;
        }
        
        /* Time slot button styles */
        .time-slot-btn {
            margin: 2px;
            padding: 5px 10px;
            border: 1px solid #ddd;
            background-color: #fff;
            color: #333;
            border-radius: 3px;
            cursor: pointer;
            transition: all 0.3s ease;
        }
        
        .time-slot-btn:hover {
            background-color: #e8f4fd;
            border-color: #337ab7;
        }
        
        .time-slot-btn.selected {
            background-color: #337ab7;
            color: white;
            border-color: #337ab7;
        }
        
        .time-slot-btn.disabled {
            background-color: #f5f5f5;
            color: #999;
            border-color: #ddd;
            cursor: not-allowed;
            opacity: 0.6;
        }
        
        .time-slot-btn.disabled:hover {
            background-color: #f5f5f5;
            border-color: #ddd;
        }
        
        .time-slots-grid {
            display: flex;
            flex-wrap: wrap;
            gap: 5px;
        }
        
        .doctor-card {
            border: 2px solid #ddd;
            border-radius: 8px;
            padding: 15px;
            margin-bottom: 15px;
            background-color: #fff;
            transition: all 0.3s ease;
        }
        
        .doctor-card.selected {
            border-color: #337ab7;
            background-color: #f8f9fa;
        }
        
        .doctor-info h5 {
            margin-bottom: 5px;
            color: #337ab7;
        }
        
        .doctor-info .specialization {
            color: #666;
            font-style: italic;
            margin-bottom: 10px;
        }
        
        .status-badge {
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: bold;
            text-transform: uppercase;
        }
        
        .status-pending {
            background-color: #fff3cd;
            color: #856404;
            border: 1px solid #ffeaa7;
        }
        
        .status-approved {
            background-color: #d1ecf1;
            color: #0c5460;
            border: 1px solid #bee5eb;
        }
        
        .current-appointment-info {
            position: relative;
        }
        
        .current-appointment-info::before {
            content: "";
            position: absolute;
            left: -1px;
            top: 0;
            bottom: 0;
            width: 4px;
            background: linear-gradient(to bottom, #007bff, #0056b3);
            border-radius: 2px;
        }
    </style>

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
        
        // Pass current appointment data for reference only (not pre-population)
        window.currentAppointment = {
            id: <%= existingAppointment.getId() %>,
            treatmentId: <%= existingAppointment.getTreatment() != null ? existingAppointment.getTreatment().getId() : "null" %>,
            doctorId: <%= existingAppointment.getDoctor() != null ? existingAppointment.getDoctor().getId() : "null" %>,
            date: "<%= existingAppointment.getAppointmentDate() != null ? existingAppointment.getAppointmentDate().toString().split(" ")[0] : "" %>",
            time: "<%= existingAppointment.getAppointmentTime() != null ? existingAppointment.getAppointmentTime().toString().substring(0, 5) : "" %>",
            message: "<%= existingAppointment.getCustMessage() != null ? existingAppointment.getCustMessage().replaceAll("\"", "\\\\\"") : "" %>"
        };
    </script>

    <!-- Include appointment.js for shared functionality -->
    <script src="<%= request.getContextPath() %>/js/appointment.js"></script>

</body>
</html>

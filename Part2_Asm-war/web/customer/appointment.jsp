<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="model.Doctor" %>
<%@ page import="model.Treatment" %>
<%@ page import="model.Customer" %>
<%
    // Check if user is logged in
    Customer loggedInCustomer = (Customer) session.getAttribute("customer");
    if (loggedInCustomer == null) {
        response.sendRedirect("login.jsp");
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
                        <form id="appointment-form" method="post" action="BookAppointmentServlet">
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
                                                <% if (treatment.getBaseConsultationCharge() > 0) { %>
                                                    - RM <%= String.format("%.2f", treatment.getBaseConsultationCharge()) %>
                                                <% } %>
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
                                    <label for="appointment_date">Choose Date:</label>
                                    <input type="date" id="appointment_date" name="appointment_date" class="form-control" required>
                                </div>
                            </div>

                            <!-- Step 3: Doctor & Time Selection -->
                            <div class="form-section hidden" id="doctor-section">
                                <h4 class="section-title"><i class="fa fa-user-md"></i> Step 3: Select Doctor & Time</h4>
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
                        You will receive a confirmation email shortly after booking.
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
    </script>

</body>
</html>

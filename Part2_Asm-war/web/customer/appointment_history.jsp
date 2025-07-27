<%--<%@page contentType="text/html" pageEncoding="UTF-8"%>--%>
<%@ page import="java.util.List" %>
<%@ page import="java.text.DecimalFormat" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="model.Doctor" %>
<%@ page import="model.Treatment" %>
<%@ page import="model.Customer" %>
<%@ page import="model.Appointment" %>
<%@ page import="model.Payment" %>
<%@ page import="model.CounterStaff" %>

<%
    // Get data from servlet
    List<Appointment> appointmentList = (List<Appointment>) request.getAttribute("appointmentList");
    List<Doctor> doctorList = (List<Doctor>) request.getAttribute("doctorList");
    List<Treatment> treatmentList = (List<Treatment>) request.getAttribute("treatmentList");
    List<Payment> paymentList = (List<Payment>) request.getAttribute("paymentList");
    List<CounterStaff> staffList = (List<CounterStaff>) request.getAttribute("staffList");

    // Get selected status filter - CHECK BOTH PARAMETER AND ATTRIBUTE
    String selectedStatus = request.getParameter("status");
    if (selectedStatus == null) {
        // Check if servlet set it as attribute
        selectedStatus = (String) request.getAttribute("statusFilter");
    }
    if (selectedStatus == null) {
        selectedStatus = "all";
    }
%>

<%
    // Check if user is logged in
    Customer loggedInCustomer = (Customer) session.getAttribute("customer");

    if (loggedInCustomer == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html lang="en">

    <head>
        <title>Appointment History - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
    </head>

    <body id="top" data-spy="scroll" data-target=".navbar-collapse" data-offset="50">

        <%--<%@ include file="/includes/preloader.jsp" %>--%>
        <%@ include file="/includes/header.jsp" %>
        <%@ include file="/includes/navbar.jsp" %>

        <%            String successMsg = request.getParameter("success");
            String errorMsg = request.getParameter("error");
        %>

        <!-- Success/Error Messages -->
        <% if (successMsg != null) { %>
        <div class="alert alert-success alert-dismissible" style="margin: 20px; position: fixed; top: 80px; right: 20px; z-index: 1000; width: 300px;" id="successAlert">
            <button type="button" class="close" data-dismiss="alert" aria-label="Close" onclick="this.parentElement.style.display='none';">
                <span aria-hidden="true">&times;</span>
            </button>
            <strong>Success!</strong> 
            <% if ("cancelled".equals(successMsg)) { %>
            Appointment cancelled successfully.
            <% } else if ("rescheduled".equals(successMsg)) { %>
            Appointment rescheduled successfully. Check your updated appointment details below.
            <% } else if ("booked".equals(successMsg)) { %>
            Appointment booked successfully! Your appointment is now pending approval from our staff.
            <% } else if ("feedback_submitted".equals(successMsg)) { %>
            Thank you! Your feedback has been submitted successfully.
            <% } else if ("receipt_generated".equals(successMsg)) { %>
            Receipt has been generated and downloaded successfully!
            <% } else { %>
            Operation completed successfully!
            <% } %>
        </div>
        <% } %>

        <% if (errorMsg != null) { %>
        <div class="alert alert-danger alert-dismissible" style="margin: 20px; position: fixed; top: 80px; right: 20px; z-index: 1000; width: 300px;" id="errorAlert">
            <button type="button" class="close" data-dismiss="alert" aria-label="Close" onclick="this.parentElement.style.display='none';">
                <span aria-hidden="true">&times;</span>
            </button>
            <strong>Error!</strong> 
            <% if ("invalid_id".equals(errorMsg)) { %>
            Invalid appointment ID provided.
            <% } else if ("not_found".equals(errorMsg)) { %>
            Appointment not found.
            <% } else if ("cannot_cancel".equals(errorMsg)) { %>
            This appointment cannot be cancelled.
            <% } else if ("cannot_reschedule".equals(errorMsg)) { %>
            This appointment cannot be rescheduled.
            <% } else if ("system_error".equals(errorMsg)) { %>
            A system error occurred. Please try again.
            <% } else if ("unauthorized".equals(errorMsg)) { %>
            You are not authorized to access this appointment.
            <% } else if ("not_completed".equals(errorMsg)) { %>
            Receipt is only available for completed appointments.
            <% } else if ("payment_not_found".equals(errorMsg)) { %>
            Payment record not found or payment is not completed.
            <% } else if ("receipt_error".equals(errorMsg)) { %>
            An error occurred while generating the receipt. Please try again later.
            <% } else if ("invalid_appointment".equals(errorMsg)) { %>
            Invalid appointment ID provided.
            <% } else if ("appointment_not_found".equals(errorMsg)) { %>
            Appointment not found.
            <% } else if ("feedback_exists".equals(errorMsg)) { %>
            You have already submitted feedback for this appointment.
            <% } else { %>
            An unexpected error occurred. Please try again.
            <% } %>
        </div>
        <% }%>

        <!-- APPOINTMENT HISTORY -->
        <section class="appointment-history" style="padding: 100px 0;">
            <div class="container">

                <div class="col-md-12 col-sm-12">
                    <div class="section-title wow fadeInUp" data-wow-delay="0.1s">
                        <h2>My Appointment History</h2>
                        <p>View and manage your medical appointments</p>
                    </div>
                </div>

                <!-- Filter Section -->
                <div class="row">
                    <div class="col-md-8 col-md-offset-2">
                        <div class="filter-section">
                            <h4><i class="fa fa-filter"></i> Filter by Status</h4>
                            <div class="form-group">
                                <label for="statusFilter">Select Appointment Status:</label>
                                <select id="statusFilter" name="status" class="form-control" onchange="filterAppointments()">
                                    <option value="all" <%= "all".equals(selectedStatus) ? "selected" : ""%>>All Appointments</option>
                                    <option value="pending" <%= "pending".equals(selectedStatus) ? "selected" : ""%>>Pending</option>
                                    <option value="reschedule" <%= "reschedule".equals(selectedStatus) ? "selected" : ""%>>Reschedule Required</option>
                                    <option value="approved" <%= "approved".equals(selectedStatus) ? "selected" : ""%>>Approved</option>
                                    <option value="overdue" <%= "overdue".equals(selectedStatus) ? "selected" : ""%>>Overdue</option>
                                    <option value="completed" <%= "completed".equals(selectedStatus) ? "selected" : ""%>>Completed</option>
                                    <option value="cancelled" <%= "cancelled".equals(selectedStatus) ? "selected" : ""%>>Cancelled</option>
                                </select>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Appointment History List -->
                <div class="row">
                    <div class="col-md-10 col-md-offset-1">
                        <%
                            if (appointmentList != null && !appointmentList.isEmpty()) {
                                DecimalFormat df = new DecimalFormat("0.00");
                                SimpleDateFormat dateFormat = new SimpleDateFormat("EEE MMM dd yyyy");
                                SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm");
                                SimpleDateFormat paymentDateFormat = new SimpleDateFormat("EEE MMM dd yyyy HH:mm");

                                boolean hasMatchingAppointments = false;

                                for (int i = 0; i < appointmentList.size(); i++) {
                                    Appointment appointment = appointmentList.get(i);

                                    // NOTE: No filtering needed here - servlet already filtered appointments
                                    // The appointmentList received is already filtered by status if requested

                                    hasMatchingAppointments = true;

                                    // Find related doctor
                                    Doctor appointmentDoctor = null;
                                    if (appointment.getDoctor() != null) {
                                        appointmentDoctor = appointment.getDoctor();
                                    }

                                    // Find related treatment
                                    Treatment appointmentTreatment = null;
                                    if (appointment.getTreatment() != null) {
                                        appointmentTreatment = appointment.getTreatment();
                                    }

                                    // Find related payment
                                    Payment appointmentPayment = null;
                                    if (paymentList != null) {
                                        for (Payment payment : paymentList) {
                                            if (payment.getAppointment() != null
                                                    && payment.getAppointment().getId() == appointment.getId()) {
                                                appointmentPayment = payment;
                                                break;
                                            }
                                        }
                                    }

                                    // Get counter staff directly from appointment
                                    CounterStaff counterStaff = appointment.getCounterStaff();
                        %>

                        <!-- Appointment Container -->
                        <div class="history-container">
                            <!-- Header -->
                            <div class="history-header">
                                <div>
                                    <h4 style="margin: 0;">Appointment #<%= appointment.getId()%></h4>
                                    <small>Booked for <%= loggedInCustomer.getName()%></small>
                                </div>
                                <div>
                                    <span class="status-badge status-<%= appointment.getStatus()%>">
                                        <%= appointment.getStatus().toUpperCase()%>
                                    </span>
                                </div>
                            </div>

                            <!-- Content -->
                            <div class="history-content">
                                <!-- Appointment Details Section -->
                                <div class="history-section">
                                    <div class="section-title">
                                        <i class="fa fa-calendar-check-o"></i> Appointment Details
                                    </div>

                                    <div class="info-row">
                                        <div class="info-label">Doctor:</div>
                                        <div class="info-value">
                                            <%= appointmentDoctor != null ? appointmentDoctor.getName() : "Not assigned"%>
                                            <% if (appointmentDoctor != null && appointmentDoctor.getSpecialization() != null) {%>
                                            - <em><%= appointmentDoctor.getSpecialization()%></em>
                                            <% }%>
                                        </div>
                                    </div>

                                    <div class="info-row">
                                        <div class="info-label">Treatment:</div>
                                        <div class="info-value">
                                            <%= appointmentTreatment != null ? appointmentTreatment.getName() : "Not specified"%>
                                        </div>
                                    </div>

                                    <div class="info-row">
                                        <div class="info-label">Counter Staff:</div>
                                        <div class="info-value">
                                            <span style="<%= counterStaff != null ? "color: #000; font-style: normal;" : "color: #999; font-style: italic;"%>">
                                                <%= counterStaff != null ? counterStaff.getName() : "Not assigned yet"%>
                                            </span>

                                        </div>
                                    </div>

                                    <div class="info-row">
                                        <div class="info-label">Date:</div>
                                        <div class="info-value">
                                            <%= appointment.getAppointmentDate() != null ? dateFormat.format(appointment.getAppointmentDate()) : "Not scheduled"%>
                                        </div>
                                    </div>

                                    <div class="info-row">
                                        <div class="info-label">Time:</div>
                                        <div class="info-value">
                                            <%= appointment.getAppointmentTime() != null ? timeFormat.format(appointment.getAppointmentTime()) : "Not scheduled"%>
                                        </div>
                                    </div>

                                    <div class="info-row">
                                        <div class="info-label">Your Message:</div>
                                        <div class="info-value">
                                            <% if (appointment.getCustMessage() != null && !appointment.getCustMessage().trim().isEmpty()) {%>
                                            "<%= appointment.getCustMessage()%>"
                                            <% } else { %>
                                            <span style="color: #999; font-style: italic;">No message provided</span>
                                            <% } %>
                                        </div>
                                    </div>

                                    <div class="info-row">
                                        <div class="info-label">Doctor's Notes:</div>
                                        <div class="info-value">
                                            <% if ("completed".equals(appointment.getStatus())
                                                        && appointment.getDocMessage() != null
                                                        && !appointment.getDocMessage().trim().isEmpty()) {%>
                                            <span style="color: #28a745; font-style: italic;">
                                                "<%= appointment.getDocMessage()%>"
                                            </span>
                                            <% } else if ("completed".equals(appointment.getStatus())) { %>
                                            <span style="color: #999; font-style: italic;">No notes provided by doctor</span>
                                            <% } else { %>
                                            <span style="color: #999; font-style: italic;">No notes yet. Available after consultation</span>
                                            <% } %>
                                        </div>
                                    </div>

                                    <div class="info-row">
                                        <div class="info-label">Staff's Notes:</div>
                                        <div class="info-value">
                                            <%
                                                String status = appointment.getStatus();
                                                String staffMessage = appointment.getStaffMessage();
                                                boolean hasStaffMessage = staffMessage != null && !staffMessage.trim().isEmpty();
                                                boolean hasCounterStaff = appointment.getCounterStaff() != null;
                                            %>

                                            <%-- Case 1: Always show staff message first if it exists --%>
                                            <% if (hasStaffMessage) { %>
                                            <div style="margin-bottom: 8px;">
                                                <span style="color: #000;">
                                                    "<%= staffMessage %>"
                                                </span>
                                            </div>
                                            <% } %>

                                            <%-- Case 2: Status is "pending", NO assigned counter staff --%>
                                            <% if ("pending".equals(status) && !hasCounterStaff) { %>
                                            <span style="color: #999; font-style: italic;">
                                                <i class="fa fa-clock-o"></i> Waiting for counter staff assignment
                                            </span>

                                            <%-- Case 3: Status is "pending", counter staff assigned, NO staff message --%>
                                            <% } else if ("pending".equals(status) && hasCounterStaff && !hasStaffMessage) { %>
                                            <span style="color: #999; font-style: italic;">
                                                <i class="fa fa-clock-o"></i> Under review by counter staff
                                            </span>

                                            <%-- Case 4: Status is "approved", counter staff assigned --%>
                                            <% } else if ("approved".equals(status)) { %>
                                            <span style="color: #28a745; font-style: italic;">
                                                <i class="fa fa-check-circle"></i> Appointment approved. We will remind you for your upcoming appointment.
                                            </span>

                                            <%-- Case 5: Status is "reschedule", counter staff assigned --%>
                                            <% } else if ("reschedule".equals(status)) { %>
                                            <span style="color: #dc3545; font-style: italic;">
                                                <i class="fa fa-calendar"></i> Reschedule requested. Please reschedule for another date again.
                                            </span>

                                            <%-- Case 6: Status is "overdue", counter staff assigned --%>
                                            <% } else if ("overdue".equals(status)) { %>
                                            <span style="color: #dc3545; font-style: italic;">
                                                <i class="fa fa-exclamation-triangle"></i> Appointment overdue. Please reschedule your appointment.
                                            </span>

                                            <%-- Case 7: Status is "completed", counter staff assigned --%>
                                            <% } else if ("completed".equals(status)) { %>
                                            <span style="color: #28a745; font-style: italic;">
                                                <i class="fa fa-check"></i> Appointment completed successfully.
                                            </span>

                                            <%-- Case 8: Status is "cancelled", counter staff assigned --%>
                                            <% } else if ("cancelled".equals(status)) { %>
                                            <span style="color: #dc3545; font-style: italic;">
                                                <i class="fa fa-times"></i> Appointment cancelled.
                                            </span>

                                            <%-- Case 9: No staff message and no counter staff assigned --%>
                                            <% } else if (!hasCounterStaff && !hasStaffMessage) { %>
                                            <span style="color: #999; font-style: italic;">
                                                <i class="fa fa-info-circle"></i> No notes available.
                                            </span>
                                            <% } %>

                                        </div>
                                    </div>

                                </div>

                                <!-- Payment Details Section -->
                                <div class="history-section">
                                    <div class="section-title">
                                        <i class="fa fa-credit-card"></i> Payment Details
                                    </div>

                                    <% if (appointmentPayment != null) {%>
                                    <div class="info-row">
                                        <div class="info-label">Payment Status:</div>
                                        <div class="info-value">
                                            <span class="status-badge payment-<%= appointmentPayment.getStatus()%>">
                                                <%= appointmentPayment.getStatus().toUpperCase()%>
                                            </span>
                                        </div>
                                    </div>

                                    <div class="info-row">
                                        <div class="info-label">Amount:</div>
                                        <div class="info-value">
                                            RM <%= df.format(appointmentPayment.getAmount())%>
                                        </div>
                                    </div>

                                    <div class="info-row">
                                        <div class="info-label">Payment Method:</div>
                                        <div class="info-value">
                                            <%= appointmentPayment.getPaymentMethod() != null
                                                    ? appointmentPayment.getPaymentMethod().substring(0, 1).toUpperCase()
                                                    + appointmentPayment.getPaymentMethod().substring(1) : "Not specified"%>
                                        </div>
                                    </div>

                                    <% if ("paid".equals(appointmentPayment.getStatus())
                                                && appointmentPayment.getPaymentDate() != null) {%>
                                    <div class="info-row">
                                        <div class="info-label">Payment Date:</div>
                                        <div class="info-value">
                                            <%= paymentDateFormat.format(appointmentPayment.getPaymentDate())%>
                                        </div>
                                    </div>
                                    <% } %>
                                    <% } else { %>
                                    <div class="info-row">
                                        <div class="info-label">Payment Status:</div>
                                        <div class="info-value">
                                            <span class="status-badge payment-pending">NO PAYMENT RECORD</span>
                                        </div>
                                    </div>
                                    <div class="info-row">
                                        <div class="info-label">Note:</div>
                                        <div class="info-value" style="color: #666; font-style: italic;">
                                            Payment information will be available once processed
                                        </div>
                                    </div>
                                    <% } %>
                                </div>

                                <!-- Action Buttons -->
                                <div class="action-buttons">
                                    <%
                                        String appointmentStatus = appointment.getStatus();

                                        // Show reschedule and cancel buttons for pending, approved, overdue, and reschedule required appointments
                                        if ("pending".equals(appointmentStatus) || "approved".equals(appointmentStatus) || "overdue".equals(appointmentStatus) || "reschedule".equals(appointmentStatus)) {
                                    %>
                                    <button type="button" class="btn-action btn-reschedule" 
                                            onclick="rescheduleAppointment(<%= appointment.getId()%>)">
                                        <i class="fa fa-calendar"></i> Reschedule
                                    </button>
                                    <button type="button" class="btn-action btn-cancel" 
                                            onclick="cancelAppointment(<%= appointment.getId()%>, '<%= appointmentStatus%>')">
                                        <i class="fa fa-times"></i> Cancel Appointment
                                    </button>
                                    <% } %>

                                    <% if ("completed".equals(appointmentStatus)) {%>
                                    <button type="button" class="btn-action btn-feedback" 
                                            onclick="submitFeedback(<%= appointment.getId()%>)">
                                        <i class="fa fa-star"></i> Submit/View Feedback
                                    </button>
                                    <% } %>

                                    <% if (appointmentPayment != null && "paid".equals(appointmentPayment.getStatus())) {%>
                                    <button type="button" class="btn-action btn-receipt" 
                                            onclick="generateReceipt(<%= appointment.getId()%>)">
                                        <i class="fa fa-file-pdf-o"></i> Download Receipt
                                    </button>
                                    <% } else { %>
                                    <button type="button" class="btn-action btn-receipt" disabled 
                                            style="background: #ccc; cursor: not-allowed;">
                                        <i class="fa fa-file-pdf-o"></i> Receipt Not Available
                                    </button>
                                    <% } %>
                                </div>
                            </div>
                        </div>
                        <% } %>
                        <%
                            // Show message if no appointments match the filter
                            if (!hasMatchingAppointments) {
                        %>
                        <div class="no-appointments">
                            <i class="fa fa-calendar-times-o" style="font-size: 64px; color: #ccc; margin-bottom: 20px;"></i>
                            <h3>No appointments found</h3>
                            <% if (selectedStatus != null && !"all".equals(selectedStatus)) {%>
                            <p>No appointments with status "<%= selectedStatus%>" were found.</p>
                            <p>Try selecting a different status or view all appointments.</p>
                            <% } else {%>
                            <p>You haven't booked any appointments yet.</p>
                            <a href="<%= request.getContextPath()%>/AppointmentServlet?action=book" class="btn btn-primary">Book Your First Appointment</a>
                            <% } %>
                        </div>
                        <%
                            }
                        } else {
                        %>
                        <div class="no-appointments">
                            <i class="fa fa-calendar-times-o" style="font-size: 64px; color: #ccc; margin-bottom: 20px;"></i>
                            <h3>No appointment history</h3>
                            <p>You haven't booked any appointments yet.</p>
                            <a href="<%= request.getContextPath()%>/AppointmentServlet?action=book" class="btn btn-primary">Book Your First Appointment</a>
                        </div>
                        <% }%>
                    </div>
                </div>
            </div>
        </section>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>

        <script>
            // Auto-hide success/error messages after 5 seconds
            document.addEventListener('DOMContentLoaded', function () {
                var alerts = document.querySelectorAll('.alert');
                alerts.forEach(function (alert) {
                    setTimeout(function () {
                        alert.style.opacity = '0';
                        setTimeout(function () {
                            alert.style.display = 'none';
                        }, 500);
                    }, 5000);
                });
            });

            // Function to submit feedback for a completed appointment
            function submitFeedback(appointmentId) {
                console.log('Submitting feedback for appointment ID:', appointmentId);

                if (!appointmentId) {
                    alert('Invalid appointment ID');
                    return;
                }

                // Redirect to feedback form with appointment ID
                window.location.href = '<%= request.getContextPath() %>/FeedbackServlet?action=show_feedback_form&appointment_id=' + appointmentId;
            }

            // Function to cancel an appointment
            function cancelAppointment(appointmentId, currentStatus) {
                console.log('Cancelling appointment ID:', appointmentId, 'Current status:', currentStatus);

                if (!appointmentId) {
                    alert('Invalid appointment ID');
                    return;
                }

                // Confirm cancellation with user
                if (confirm('Are you sure you want to cancel this appointment?\n\nThis action cannot be undone.')) {
                    // Create a form to submit the cancellation request
                    var form = document.createElement('form');
                    form.method = 'POST';
                    form.action = '<%= request.getContextPath() %>/AppointmentServlet';

                    // Add action parameter
                    var actionInput = document.createElement('input');
                    actionInput.type = 'hidden';
                    actionInput.name = 'action';
                    actionInput.value = 'cancel';
                    form.appendChild(actionInput);

                    // Add appointment ID parameter
                    var idInput = document.createElement('input');
                    idInput.type = 'hidden';
                    idInput.name = 'appointmentId';
                    idInput.value = appointmentId;
                    form.appendChild(idInput);

                    // Add current status parameter
                    var statusInput = document.createElement('input');
                    statusInput.type = 'hidden';
                    statusInput.name = 'currentStatus';
                    statusInput.value = currentStatus;
                    form.appendChild(statusInput);

                    // Submit form
                    document.body.appendChild(form);
                    form.submit();
                }
            }

            // Function to reschedule an appointment
            function rescheduleAppointment(appointmentId) {
                console.log('Rescheduling appointment ID:', appointmentId);

                if (!appointmentId) {
                    alert('Invalid appointment ID');
                    return;
                }

                // Redirect to reschedule form with appointment ID
                window.location.href = '<%= request.getContextPath() %>/AppointmentServlet?action=reschedule&id=' + appointmentId;
            }

            // Function to filter appointments by status
            function filterAppointments() {
                const status = document.getElementById('statusFilter').value;
                window.location.href = '<%= request.getContextPath() %>/AppointmentServlet?action=history&status=' + status;
            }

            // Function to generate receipt for completed appointments
            function generateReceipt(appointmentId) {
                console.log('Generating receipt for appointment ID:', appointmentId);

                if (!appointmentId) {
                    alert('Invalid appointment ID');
                    return;
                }

                // Open receipt in new window/tab
                window.open('<%= request.getContextPath() %>/ReceiptServlet?appointmentId=' + appointmentId, '_blank');
            }
        </script>


    </body>

</html>

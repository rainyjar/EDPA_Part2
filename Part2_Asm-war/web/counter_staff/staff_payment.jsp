<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ page import="java.text.*" %>
<%@ page import="model.*" %>
<%
    // Get data from request
    List<Payment> payments = (List<Payment>) request.getAttribute("payments");
    CounterStaff staff = (CounterStaff) request.getAttribute("staff");
    String statusFilter = (String) request.getAttribute("statusFilter");
    SimpleDateFormat dateFormat = (SimpleDateFormat) request.getAttribute("dateFormat");
    SimpleDateFormat timeFormat = (SimpleDateFormat) request.getAttribute("timeFormat");
    DecimalFormat decimalFormat = (DecimalFormat) request.getAttribute("decimalFormat");
    
    String successMsg = request.getParameter("success");
    String errorMsg = (String) request.getAttribute("error");
    
    if (statusFilter == null) statusFilter = "all";
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Payment Processing - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manager-homepage.css">
        <style>
            .payment-card {
                border: 1px solid #ddd;
                border-radius: 8px;
                padding: 20px;
                margin-bottom: 20px;
                background: white;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                transition: transform 0.2s;
            }
            .payment-card:hover {
                transform: translateY(-2px);
                box-shadow: 0 4px 8px rgba(0,0,0,0.15);
            }
            .payment-card.paid {
                background: #f8f9fa;
                border-color: #28a745;
            }
            .payment-header {
                display: flex;
                justify-content: space-between;
                align-items: center;
                margin-bottom: 15px;
                padding-bottom: 10px;
                border-bottom: 1px solid #eee;
            }
            .payment-id {
                font-weight: bold;
                color: #667eea;
                font-size: 1.2em;
            }
            .status-badge {
                padding: 6px 12px;
                border-radius: 20px;
                font-size: 0.85em;
                font-weight: bold;
                text-transform: uppercase;
            }
            .status-pending { background: #fff3cd; color: #856404; }
            .status-paid { background: #d4edda; color: #155724; }
            .payment-details {
                display: grid;
                grid-template-columns: 1fr 1fr 1fr;
                gap: 20px;
                margin-bottom: 20px;
            }
            .detail-item {
                margin-bottom: 10px;
            }
            .detail-label {
                font-weight: bold;
                color: #666;
                display: block;
                margin-bottom: 5px;
            }
            .detail-value {
                color: #333;
            }
            .amount-display {
                font-size: 1.3em;
                font-weight: bold;
                color: #28a745;
            }
            .filter-section {
                background: white;
                padding: 20px;
                border-radius: 8px;
                margin-bottom: 20px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            }
            .payment-actions {
                text-align: center;
                padding-top: 15px;
                border-top: 1px solid #eee;
            }
            .btn-group-custom {
                display: flex;
                gap: 10px;
                justify-content: center;
            }
            .modal-body .form-group {
                margin-bottom: 20px;
            }
            .readonly-field {
                background-color: #f8f9fa;
                border: 1px solid #e9ecef;
            }
        </style>
    </head>

    <body id="top">
        <%@ include file="/includes/header.jsp" %>
        <%@ include file="/includes/navbar.jsp" %>

        <!-- PAGE HEADER -->
        <section class="page-header">
            <div class="container">
                <div class="row">
                    <div class="col-md-12">
                        <h1 class="wow fadeInUp">
                            <i class="fa fa-credit-card" style="color:white"></i>
                            <span style="color:white">Payment Processing</span>
                        </h1>
                        <p class="lead wow fadeInUp" data-wow-delay="0.2s" style="color: whitesmoke">
                            Process payments for completed appointments
                        </p>
                        <nav aria-label="breadcrumb" class="wow fadeInUp" data-wow-delay="0.3s">
                            <ol class="breadcrumb" style="background: transparent; margin: 0;">
                                <li class="breadcrumb-item">
                                    <a href="<%= request.getContextPath()%>/CounterStaffServlet?action=dashboard" style="color: rgba(255,255,255,0.8);">Dashboard</a> 
                                </li>
                                <li class="breadcrumb-item active" style="color: white;">Payment Processing</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>
        </section>

        <!-- MAIN CONTENT -->
        <section style="padding: 40px 0; background: #f5f5f5;">
            <div class="container">
                <!-- Success/Error Messages -->
                <% if (successMsg != null) { %>
                <div class="alert alert-success alert-dismissible wow fadeInUp">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <i class="fa fa-check-circle"></i>
                    <%= successMsg %>
                </div>
                <% } %>

                <% if (errorMsg != null) { %>
                <div class="alert alert-danger alert-dismissible wow fadeInUp">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <i class="fa fa-exclamation-triangle"></i>
                    <%= errorMsg %>
                </div>
                <% } %>

                <!-- FILTER SECTION -->
                <div class="filter-section wow fadeInUp" data-wow-delay="0.2s">
                    <h4><i class="fa fa-filter"></i> Filter Payments</h4>
                    <form method="GET" action="<%= request.getContextPath()%>/PaymentServlet">
                        <input type="hidden" name="action" value="viewPayments">
                        <div class="row">
                            <div class="col-md-4">
                                <div class="form-group">
                                    <label for="status">Payment Status:</label>
                                    <select class="form-control" id="status" name="status" onchange="this.form.submit()">
                                        <option value="all" <%= "all".equals(statusFilter) ? "selected" : "" %>>All Payments</option>
                                        <option value="pending" <%= "pending".equals(statusFilter) ? "selected" : "" %>>Pending</option>
                                        <option value="paid" <%= "paid".equals(statusFilter) ? "selected" : "" %>>Paid</option>
                                    </select>
                                </div>
                            </div>
                        </div>
                    </form>
                </div>

                <!-- PAYMENTS SECTION -->
                <div class="payments-section wow fadeInUp" data-wow-delay="0.4s">
                    <div class="d-flex justify-content-between align-items-center mb-4">
                        <h3><i class="fa fa-list"></i> Payments 
                            (<%= payments != null ? payments.size() : 0%>)
                        </h3>
                    </div>

                    <!-- Payments List -->
                    <div class="payments-list">
                        <% if (payments != null && !payments.isEmpty()) { %>
                            <% for (Payment payment : payments) { 
                                String statusClass = "status-" + (payment.getStatus() != null ? payment.getStatus().toLowerCase() : "pending");
                                boolean isPaid = "paid".equals(payment.getStatus());
                                Appointment appointment = payment.getAppointment();
                            %>
                            <div class="payment-card <%= isPaid ? "paid" : "" %>">
                                <div class="payment-header">
                                    <div class="payment-id">
                                        Payment #<%= payment.getId() %>
                                        <small class="text-muted">(Appointment #<%= appointment != null ? appointment.getId() : "N/A" %>)</small>
                                    </div>
                                    <span class="status-badge <%= statusClass %>">
                                        <%= payment.getStatus() != null ? payment.getStatus().toUpperCase() : "PENDING" %>
                                    </span>
                                </div>

                                <div class="payment-details">
                                    <!-- Appointment Info -->
                                    <div class="detail-group">
                                        <div class="detail-item">
                                            <span class="detail-label">Date & Time:</span>
                                            <span class="detail-value">
                                                <%= appointment != null && appointment.getAppointmentDate() != null ? dateFormat.format(appointment.getAppointmentDate()) : "N/A" %>
                                                <%= appointment != null && appointment.getAppointmentTime() != null ? timeFormat.format(appointment.getAppointmentTime()) : "" %>
                                            </span>
                                        </div>
                                        <div class="detail-item">
                                            <span class="detail-label">Patient:</span>
                                            <span class="detail-value">
                                                <%= appointment != null && appointment.getCustomer() != null ? appointment.getCustomer().getName() : "N/A" %>
                                            </span>
                                        </div>
                                        <div class="detail-item">
                                            <span class="detail-label">Treatment:</span>
                                            <span class="detail-value">
                                                <%= appointment != null && appointment.getTreatment() != null ? appointment.getTreatment().getName() : "N/A" %>
                                            </span>
                                        </div>
                                    </div>

                                    <!-- Payment Info -->
                                    <div class="detail-group">
                                        <div class="detail-item">
                                            <span class="detail-label">Amount:</span>
                                            <span class="detail-value amount-display">
                                                RM <%= decimalFormat != null ? decimalFormat.format(payment.getAmount()) : String.format("%.2f", payment.getAmount()) %>
                                            </span>
                                        </div>
                                        <% if (isPaid) { %>
                                        <div class="detail-item">
                                            <span class="detail-label">Payment Method:</span>
                                            <span class="detail-value">
                                                <%= payment.getPaymentMethod() != null ? payment.getPaymentMethod().toUpperCase() : "N/A" %>
                                            </span>
                                        </div>
                                        <div class="detail-item">
                                            <span class="detail-label">Paid Date:</span>
                                            <span class="detail-value">
                                                <%= payment.getPaymentDate() != null ? new SimpleDateFormat("yyyy-MM-dd HH:mm").format(payment.getPaymentDate()) : "N/A" %>
                                            </span>
                                        </div>
                                        <% } %>
                                    </div>

                                    <!-- Doctor Notes -->
                                    <div class="detail-group">
                                        <div class="detail-item">
                                            <span class="detail-label">Doctor:</span>
                                            <span class="detail-value">
                                                <%= appointment != null && appointment.getDoctor() != null ? "Dr. " + appointment.getDoctor().getName() : "N/A" %>
                                            </span>
                                        </div>
                                        <% if (appointment != null && appointment.getDocMessage() != null && !appointment.getDocMessage().trim().isEmpty()) { %>
                                        <div class="detail-item">
                                            <span class="detail-label">Doctor Notes:</span>
                                            <span class="detail-value">
                                                <%= appointment.getDocMessage() %>
                                            </span>
                                        </div>
                                        <% } %>
                                    </div>
                                </div>

                                <!-- Action Buttons -->
                                <div class="payment-actions">
                                    <% if (!isPaid) { %>
                                    <div class="btn-group-custom">
                                        <button class="btn btn-success" onclick="showPaymentModal(<%= payment.getId() %>, <%= payment.getAmount() %>)">
                                            <i class="fa fa-credit-card"></i> View & Pay
                                        </button>
                                    </div>
                                    <% } else { %>
                                    <div class="btn-group-custom">
                                        <button class="btn btn-info" 
                                                onclick="generateReceipt(<%= payment.getId() %>)">
                                            <i class="fa fa-file-pdf-o"></i> Generate Receipt
                                        </button>
                                        <button class="btn btn-secondary" onclick="generateMC(<%= appointment.getId() %>)">
                                            <i class="fa fa-file-text-o"></i> Generate MC
                                        </button>
                                    </div>
                                    <% } %>
                                </div>
                            </div>
                            <% } %>
                        <% } else { %>
                        <div class="no-data text-center">
                            <i class="fa fa-credit-card" style="font-size: 4em; color: #ccc; margin-bottom: 20px;"></i>
                            <h4>No Payments Found</h4>
                            <p>No payments match your current filter criteria.</p>
                        </div>
                        <% } %>
                    </div>
                </div>
            </div>
        </section>

        <!-- Payment Processing Modal -->
        <div class="modal fade" id="paymentModal" tabindex="-1" role="dialog">
            <div class="modal-dialog" role="document">
                <div class="modal-content">
                    <div class="modal-header">
                        <h4 class="modal-title">
                            <i class="fa fa-credit-card"></i> Process Payment
                        </h4>
                        <button type="button" class="close" data-dismiss="modal">&times;</button>
                    </div>
                    <form id="paymentForm" method="post" action="<%= request.getContextPath()%>/PaymentServlet">
                        <div class="modal-body">
                            <input type="hidden" name="action" value="processPayment">
                            <input type="hidden" name="paymentId" id="modalPaymentId">
                            
                            <div class="form-group">
                                <label for="modalPaymentAmount">Payment Amount:</label>
                                <div class="input-group">
                                    <div class="input-group-prepend">
                                        <span class="input-group-text">RM</span>
                                    </div>
                                    <input type="text" class="form-control readonly-field" id="modalPaymentAmount" readonly>
                                </div>
                            </div>
                            
                            <div class="form-group">
                                <label for="paymentMethod">Payment Method: *</label>
                                <select class="form-control" name="paymentMethod" id="paymentMethod" required>
                                    <option value="">Select Payment Method</option>
                                    <option value="cash">Cash</option>
                                    <option value="online">Online Payment</option>
                                </select>
                            </div>
                            
                            <div class="alert alert-warning">
                                <i class="fa fa-info-circle"></i>
                                <strong>Confirm Payment:</strong> Please ensure the payment amount has been received before marking as paid.
                            </div>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-success" onclick="confirmPayment()">
                                <i class="fa fa-check"></i> Mark as Paid
                            </button>
                            <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>

        <script>
            function showPaymentModal(paymentId, amount) {
                document.getElementById('modalPaymentId').value = paymentId;
                document.getElementById('modalPaymentAmount').value = amount.toFixed(2);
                document.getElementById('paymentMethod').value = '';
                $('#paymentModal').modal('show');
            }
            
            function confirmPayment() {
                const paymentId = document.getElementById('modalPaymentId').value;
                const amount = document.getElementById('modalPaymentAmount').value;
                const method = document.getElementById('paymentMethod').value;
                
                if (!method) {
                    alert('Please select a payment method.');
                    return;
                }
                
                if (confirm('Confirm payment of RM ' + amount + ' for Payment ID: ' + paymentId + '?')) {
                    document.getElementById('paymentForm').submit();
                }
            }
            
            function generateReceipt(paymentId) {
                window.open('<%= request.getContextPath()%>/ReceiptServlet?paymentId=' + paymentId, '_blank');
            }
            
            function generateMC(appointmentId) {
                window.open('<%= request.getContextPath()%>/MedicalCertificateServlet?appointmentId=' + appointmentId, '_blank');
            }
        </script>
    </body>
</html>

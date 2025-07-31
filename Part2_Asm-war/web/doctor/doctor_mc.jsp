<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.*" %>
<%@ page import="model.*" %>
<%
    // Get data from request
    Appointment appointment = (Appointment) request.getAttribute("appointment");
    MedicalCertificate existingMC = (MedicalCertificate) request.getAttribute("existingMC");
    Doctor doctor = (Doctor) request.getAttribute("doctor");
    
    String successMsg = (String) request.getAttribute("success");
    String errorMsg = (String) request.getAttribute("error");
    
    SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");
    boolean isUpdate = existingMC != null;
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Medical Certificate - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/doctor-homepage.css">
        <style>
            .mc-form {
                background: white;
                padding: 30px;
                border-radius: 8px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                margin-bottom: 20px;
            }
            .appointment-info {
                background: #f8f9fa;
                padding: 20px;
                border-radius: 8px;
                margin-bottom: 30px;
                border-left: 4px solid #667eea;
            }
            .form-section {
                margin-bottom: 30px;
                padding-bottom: 20px;
                border-bottom: 1px solid #eee;
            }
            .form-section:last-child {
                border-bottom: none;
            }
            .section-title {
                color: #667eea;
                font-weight: bold;
                margin-bottom: 15px;
                display: flex;
                align-items: center;
            }
            .section-title i {
                margin-right: 10px;
            }
            .form-row {
                display: flex;
                gap: 20px;
                margin-bottom: 15px;
            }
            .form-group {
                flex: 1;
            }
            .readonly-field {
                background-color: #f8f9fa;
                border: 1px solid #e9ecef;
            }
            .date-input-group {
                display: flex;
                align-items: center;
                gap: 10px;
            }
            .btn-group-custom {
                display: flex;
                gap: 15px;
                justify-content: center;
                margin-top: 30px;
            }
            .preview-section {
                background: #f8f9fa;
                padding: 20px;
                border-radius: 8px;
                border: 1px solid #dee2e6;
                margin-top: 20px;
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
                            <i class="fa fa-file-text-o" style="color:white"></i>
                            <span style="color:white">Medical Certificate</span>
                        </h1>
                        <p class="lead wow fadeInUp" data-wow-delay="0.2s" style="color: whitesmoke">
                            <%= isUpdate ? "Update" : "Create" %> medical certificate for completed appointment
                        </p>
                        <nav aria-label="breadcrumb" class="wow fadeInUp" data-wow-delay="0.3s">
                            <ol class="breadcrumb" style="background: transparent; margin: 0;">
                                <li class="breadcrumb-item">
                                    <a href="<%= request.getContextPath()%>/DoctorServlet?action=dashboard" style="color: rgba(255,255,255,0.8);">Dashboard</a> 
                                </li>
                                <li class="breadcrumb-item">
                                    <a href="<%= request.getContextPath()%>/PaymentServlet?action=viewAssignedAppointments" style="color: rgba(255,255,255,0.8);">Assigned Appointments</a> 
                                </li>
                                <li class="breadcrumb-item active" style="color: white;">Medical Certificate</li>
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

                <!-- APPOINTMENT INFO -->
                <% if (appointment != null) { %>
                <div class="appointment-info wow fadeInUp" data-wow-delay="0.2s">
                    <h4><i class="fa fa-info-circle"></i> Appointment Details</h4>
                    <div class="row">
                        <div class="col-md-6">
                            <p><strong>Appointment ID:</strong> #<%= appointment.getId() %></p>
                            <p><strong>Patient:</strong> <%= appointment.getCustomer() != null ? appointment.getCustomer().getName() : "N/A" %></p>
                            <p><strong>Age:</strong> <%= appointment.getCustomer() != null && appointment.getCustomer().getDob() != null ? calculateAge(appointment.getCustomer().getDob()) : "N/A" %> years</p>
                        </div>
                        <div class="col-md-6">
                            <p><strong>Date:</strong> <%= appointment.getAppointmentDate() != null ? new SimpleDateFormat("dd MMMM yyyy").format(appointment.getAppointmentDate()) : "N/A" %></p>
                            <p><strong>Treatment:</strong> <%= appointment.getTreatment() != null ? appointment.getTreatment().getName() : "N/A" %></p>
                            <p><strong>Status:</strong> <span class="badge badge-success">COMPLETED</span></p>
                        </div>
                    </div>
                </div>
                <% } %>

                <!-- MC FORM -->
                <div class="mc-form wow fadeInUp" data-wow-delay="0.4s">
                    <h3><i class="fa fa-file-text-o"></i> Medical Certificate Form</h3>
                    
                    <form id="mcForm" method="post" action="<%= request.getContextPath()%>/MedicalCertificateServlet" onsubmit="return validateForm()">
                        <input type="hidden" name="action" value="createMC">
                        <input type="hidden" name="appointmentId" value="<%= appointment != null ? appointment.getId() : "" %>">
                        
                        <!-- Medical Center Information (Read-only) -->
                        <div class="form-section">
                            <h5 class="section-title">
                                <i class="fa fa-hospital-o"></i>
                                Medical Center Information
                            </h5>
                            <div class="form-row">
                                <div class="form-group">
                                    <label>Medical Center Name:</label>
                                    <input type="text" class="form-control readonly-field" value="APU Medical Center" readonly>
                                </div>
                                <div class="form-group">
                                    <label>Registration Number:</label>
                                    <input type="text" class="form-control readonly-field" value="KKM-APU-2024-001" readonly>
                                </div>
                            </div>
                            <div class="form-row">
                                <div class="form-group">
                                    <label>Address:</label>
                                    <input type="text" class="form-control readonly-field" value="Technology Park Malaysia, 57000 Kuala Lumpur" readonly>
                                </div>
                                <div class="form-group">
                                    <label>Contact:</label>
                                    <input type="text" class="form-control readonly-field" value="+603-8996-1000" readonly>
                                </div>
                            </div>
                        </div>

                        <!-- Patient Information (Read-only) -->
                        <div class="form-section">
                            <h5 class="section-title">
                                <i class="fa fa-user"></i>
                                Patient Information
                            </h5>
                            <div class="form-row">
                                <div class="form-group">
                                    <label>Full Name:</label>
                                    <input type="text" class="form-control readonly-field" 
                                           value="<%= appointment != null && appointment.getCustomer() != null ? appointment.getCustomer().getName() : "" %>" readonly>
                                </div>
                                <div class="form-group">
                                    <label>Age:</label>
                                    <input type="text" class="form-control readonly-field" 
                                           value="<%= appointment != null && appointment.getCustomer() != null && appointment.getCustomer().getDob() != null ? calculateAge(appointment.getCustomer().getDob()) + " years" : "N/A" %>" readonly>
                                </div>
                                <div class="form-group">
                                    <label>Gender:</label>
                                    <input type="text" class="form-control readonly-field" 
                                           value="<%= appointment != null && appointment.getCustomer() != null ? appointment.getCustomer().getGender() : "" %>" readonly>
                                </div>
                            </div>
                        </div>

                        <!-- Medical Certificate Period -->
                        <div class="form-section">
                            <h5 class="section-title">
                                <i class="fa fa-calendar"></i>
                                Medical Certificate Period
                            </h5>
                            <div class="form-row">
                                <div class="form-group">
                                    <label for="startDate">Start Date: *</label>
                                    <input type="date" class="form-control" name="startDate" id="startDate" 
                                           value="<%= isUpdate ? dateFormat.format(existingMC.getStartDate()) : dateFormat.format(appointment.getAppointmentDate()) %>"
                                           required onchange="calculateDuration()">
                                </div>
                                <div class="form-group">
                                    <label for="endDate">End Date: *</label>
                                    <input type="date" class="form-control" name="endDate" id="endDate" 
                                           value="<%= isUpdate ? dateFormat.format(existingMC.getEndDate()) : dateFormat.format(appointment.getAppointmentDate()) %>"
                                           required onchange="calculateDuration()">
                                </div>
                                <div class="form-group">
                                    <label>Duration:</label>
                                    <input type="text" class="form-control readonly-field" id="duration" readonly>
                                </div>
                            </div>
                        </div>

                        <!-- Reason for Medical Leave -->
                        <div class="form-section">
                            <h5 class="section-title">
                                <i class="fa fa-stethoscope"></i>
                                Medical Information
                            </h5>
                            <div class="form-group">
                                <label for="reason">Reason for Medical Leave:</label>
                                <select class="form-control" name="reason" id="reason" onchange="handleReasonChange()">
                                    <option value="">Select reason</option>
                                    <option value="Fever" <%= isUpdate && "Fever".equals(existingMC.getReason()) ? "selected" : "" %>>Fever</option>
                                    <option value="Flu" <%= isUpdate && "Flu".equals(existingMC.getReason()) ? "selected" : "" %>>Flu</option>
                                    <option value="Food Poisoning" <%= isUpdate && "Food Poisoning".equals(existingMC.getReason()) ? "selected" : "" %>>Food Poisoning</option>
                                    <option value="Migraine" <%= isUpdate && "Migraine".equals(existingMC.getReason()) ? "selected" : "" %>>Migraine</option>
                                    <option value="Medical Treatment" <%= isUpdate && "Medical Treatment".equals(existingMC.getReason()) ? "selected" : "" %>>Medical Treatment</option>
                                    <option value="Recovery" <%= isUpdate && "Recovery".equals(existingMC.getReason()) ? "selected" : "" %>>Recovery</option>
                                    <option value="Other" <%= isUpdate && "Other".equals(existingMC.getReason()) ? "selected" : "" %>>Other</option>
                                    <option value="Medically Unfit" <%= isUpdate && "Medically Unfit".equals(existingMC.getReason()) ? "selected" : "" %>>Medically Unfit (General)</option>
                                </select>
                            </div>
                            
                            <div class="form-group">
                                <label for="additionalNotes">Additional Notes (Optional):</label>
                                <textarea class="form-control" name="additionalNotes" id="additionalNotes" rows="4" 
                                         placeholder="Any additional medical notes or instructions..."><%= isUpdate && existingMC.getAdditionalNotes() != null ? existingMC.getAdditionalNotes() : "" %></textarea>
                            </div>
                        </div>

                        <!-- Doctor Information (Read-only) -->
                        <div class="form-section">
                            <h5 class="section-title">
                                <i class="fa fa-user-md"></i>
                                Doctor Information
                            </h5>
                            <div class="form-row">
                                <div class="form-group">
                                    <label>Doctor Name:</label>
                                    <input type="text" class="form-control readonly-field" 
                                           value="Dr. <%= doctor != null ? doctor.getName() : "" %>" readonly>
                                </div>
                                <div class="form-group">
                                    <label>Specialization:</label>
                                    <input type="text" class="form-control readonly-field" 
                                           value="<%= doctor != null ? doctor.getSpecialization() : "" %>" readonly>
                                </div>
                                <div class="form-group">
                                    <label>Issue Date:</label>
                                    <input type="text" class="form-control readonly-field" 
                                           value="<%= new SimpleDateFormat("dd MMMM yyyy").format(new Date()) %>" readonly>
                                </div>
                            </div>
                        </div>

                        <!-- Form Actions -->
                        <div class="btn-group-custom">
                            <button type="button" class="btn btn-info" onclick="previewMC()">
                                <i class="fa fa-eye"></i> Preview
                            </button>
                            <button type="submit" class="btn btn-success">
                                <i class="fa fa-save"></i> <%= isUpdate ? "Update" : "Save" %> Medical Certificate
                            </button>
                            <% if (isUpdate) { %>
                            <button type="button" class="btn btn-primary" onclick="downloadMC()">
                                <i class="fa fa-download"></i> Download PDF
                            </button>
                            <% } %>
                            <a href="<%= request.getContextPath()%>/PaymentServlet?action=viewAssignedAppointments" class="btn btn-secondary">
                                <i class="fa fa-arrow-left"></i> Back to Appointments
                            </a>
                        </div>
                    </form>
                </div>

                <!-- Preview Section -->
                <div id="previewSection" class="preview-section" style="display: none;">
                    <h4><i class="fa fa-eye"></i> Medical Certificate Preview</h4>
                    <div id="previewContent"></div>
                </div>
            </div>
        </section>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>

        <script>
            function calculateAge(dobString) {
                const dob = new Date(dobString);
                const today = new Date();
                let age = today.getFullYear() - dob.getFullYear();
                const monthDiff = today.getMonth() - dob.getMonth();
                
                if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < dob.getDate())) {
                    age--;
                }
                
                return age;
            }
            
            function calculateDuration() {
                const startDate = new Date(document.getElementById('startDate').value);
                const endDate = new Date(document.getElementById('endDate').value);
                
                if (startDate && endDate && endDate >= startDate) {
                    const timeDiff = endDate.getTime() - startDate.getTime();
                    const dayDiff = Math.ceil(timeDiff / (1000 * 3600 * 24)) + 1; // Include both start and end dates
                    
                    document.getElementById('duration').value = dayDiff + ' day(s)';
                } else {
                    document.getElementById('duration').value = '';
                }
            }
            
            function handleReasonChange() {
                const reason = document.getElementById('reason').value;
                const additionalNotes = document.getElementById('additionalNotes');
                
                if (reason === 'Other') {
                    additionalNotes.placeholder = 'Please specify the reason for medical leave...';
                    additionalNotes.required = true;
                } else {
                    additionalNotes.placeholder = 'Any additional medical notes or instructions...';
                    additionalNotes.required = false;
                }
            }
            
            function validateForm() {
                const startDate = new Date(document.getElementById('startDate').value);
                const endDate = new Date(document.getElementById('endDate').value);
                const reason = document.getElementById('reason').value;
                
                if (endDate < startDate) {
                    alert('End date cannot be earlier than start date.');
                    return false;
                }
                
                if (!reason) {
                    alert('Please select a reason for medical leave.');
                    return false;
                }
                
                if (reason === 'Other' && !document.getElementById('additionalNotes').value.trim()) {
                    alert('Please specify the reason in additional notes when "Other" is selected.');
                    return false;
                }
                
                return confirm('Are you sure you want to <%= isUpdate ? "update" : "save" %> this medical certificate?');
            }
            
            function previewMC() {
                const patientName = '<%= appointment != null && appointment.getCustomer() != null ? appointment.getCustomer().getName() : "" %>';
                const patientAge = '<%= appointment != null && appointment.getCustomer() != null && appointment.getCustomer().getDob() != null ? calculateAge(appointment.getCustomer().getDob()) : "" %>';
                const startDate = document.getElementById('startDate').value;
                const endDate = document.getElementById('endDate').value;
                const reason = document.getElementById('reason').value;
                const additionalNotes = document.getElementById('additionalNotes').value;
                const doctorName = 'Dr. <%= doctor != null ? doctor.getName() : "" %>';
                const specialization = '<%= doctor != null ? doctor.getSpecialization() : "" %>';
                
                const previewContent =
                '<div style="border: 1px solid #ccc; padding: 20px; background: white;">' +
                    '<div style="text-align: center; margin-bottom: 20px;">' +
                        '<h3>APU MEDICAL CENTER</h3>' +
                        '<p>Technology Park Malaysia, 57000 Kuala Lumpur<br>' +
                        'Tel: +603-8996-1000 | Email: info@apu.edu.my</p>' +
                    '</div>' +

                    '<h3 style="text-align: center; margin: 20px 0;">MEDICAL CERTIFICATE</h3>' +

                    '<p><strong>Patient Details:</strong></p>' +
                    '<p>Name: ' + patientName + '<br>' +
                    'Age: ' + patientAge + ' years</p>' +

                    '<p><strong>Medical Statement:</strong></p>' +
                    '<p>This is to certify that the above-named individual has been examined and found to be medically unfit for work/school from ' +
                    new Date(startDate).toLocaleDateString() + ' to ' + new Date(endDate).toLocaleDateString() + '.</p>' +

                    (reason ? '<p><strong>Reason:</strong> ' + reason + '</p>' : '') +
                    (additionalNotes ? '<p><strong>Additional Notes:</strong> ' + additionalNotes + '</p>' : '') +

                    '<p><strong>Date of Issue:</strong> ' + new Date().toLocaleDateString() + '</p>' +

                    '<div style="margin-top: 40px;">' +
                        '<p><strong>Doctor Information:</strong><br>' +
                        'Name: ' + doctorName + '<br>' +
                        'Specialization: ' + specialization + '</p>' +

                        '<div style="margin-top: 40px;">' +
                            '<p>_________________________<br>' +
                            "Doctor's Signature</p>" +
                        '</div>' +
                    '</div>' +
                '</div>';
                
                document.getElementById('previewContent').innerHTML = previewContent;
                document.getElementById('previewSection').style.display = 'block';
                document.getElementById('previewSection').scrollIntoView({ behavior: 'smooth' });
            }
            
            function downloadMC() {
                const appointmentId = '<%= appointment != null ? appointment.getId() : "" %>';
                window.open('<%= request.getContextPath()%>/MedicalCertificateServlet?appointmentId=' + appointmentId, '_blank');
            }
            
            // Initialize on page load
            window.onload = function() {
                calculateDuration();
                handleReasonChange();
            };
        </script>
    </body>
</html>

<%!
    // Helper method to calculate age
    private int calculateAge(java.util.Date dob) {
        if (dob == null) return 0;
        
        Calendar today = Calendar.getInstance();
        Calendar birth = Calendar.getInstance();
        birth.setTime(dob);
        
        int age = today.get(Calendar.YEAR) - birth.get(Calendar.YEAR);
        
        if (today.get(Calendar.DAY_OF_YEAR) < birth.get(Calendar.DAY_OF_YEAR)) {
            age--;
        }
        
        return age;
    }
%>

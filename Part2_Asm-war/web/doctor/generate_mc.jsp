<%@ page language="java" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ page import="java.text.*" %>
<%@ page import="model.*" %>
<%
    // Check if doctor is logged in
    Doctor loggedInDoctor = (Doctor) session.getAttribute("doctor");
    if (loggedInDoctor == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // Get data from request attributes
    List<Appointment> completedAppointments = (List<Appointment>) request.getAttribute("completedAppointments");
    String successMsg = (String) request.getAttribute("success");
    String errorMsg = (String) request.getAttribute("error");
    
    // Format for dates
    SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");
    SimpleDateFormat displayFormat = new SimpleDateFormat("dd MMM yyyy");
    String today = dateFormat.format(new Date());
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <title>Generate Medical Certificate - APU Medical Center</title>
    <%@ include file="/includes/head.jsp" %>
    <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manager-homepage.css">
    <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manage-staff.css">

    <style>
        .mc-container {
            background: white;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            margin-bottom: 30px;
        }
        
        .mc-header {
            background: linear-gradient(45deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 10px 10px 0 0;
        }
        
        .mc-body {
            padding: 30px;
        }
        
        .appointment-card {
            border: 1px solid #e3e6f0;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
            background: #f8f9fc;
            transition: transform 0.2s;
        }
        
        .appointment-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(0,0,0,0.15);
        }
        
        .appointment-info {
            display: grid;
            grid-template-columns: 1fr 1fr 1fr;
            gap: 20px;
            margin-bottom: 15px;
        }
        
        .info-item {
            display: flex;
            flex-direction: column;
        }
        
        .info-label {
            font-weight: bold;
            color: #666;
            font-size: 0.9em;
            margin-bottom: 5px;
        }
        
        .info-value {
            color: #333;
            font-size: 1em;
        }

        .badge {
            background-color: #28a745;
        }
        
        .form-section {
            background: #f8f9fc;
            border: 1px solid #e3e6f0;
            border-radius: 8px;
            padding: 25px;
            margin: 20px 0;
        }
        
        .section-title {
            color: #667eea;
            font-weight: bold;
            margin-bottom: 20px;
            font-size: 1.2em;
            border-bottom: 2px solid #667eea;
            padding-bottom: 10px;
        }
        
        .form-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-bottom: 20px;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-control {
            border: 1px solid #d1d3e2;
            border-radius: 5px;
            padding: 12px;
            font-size: 0.95em;
            transition: border-color 0.3s;
        }
        
        .form-control:focus {
            border-color: #667eea;
            box-shadow: 0 0 0 0.2rem rgba(102, 126, 234, 0.25);
        }
        
        .btn-generate {
            background: linear-gradient(45deg, #667eea 0%, #764ba2 100%);
            border: none;
            color: white;
            padding: 12px 30px;
            border-radius: 25px;
            font-weight: bold;
            transition: transform 0.2s;
        }
        
        .btn-generate:hover {
            transform: translateY(-2px);
            color: white;
        }
        
        .patient-info-card {
            background: white;
            border: 1px solid #e3e6f0;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
        }
        
        .readonly-field {
            background-color: #e9ecef;
            cursor: not-allowed;
        }
        
        .required {
            color: #e74a3b;
        }
            
        .mc-title {
            text-align: center;
            font-size: 1.5em;
            font-weight: bold;
            color: #667eea;
            margin-bottom: 20px;
            text-transform: uppercase;
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
                        <span style="color:white">Generate Medical Certificate</span>
                    </h1>
                    <p class="lead wow fadeInUp" data-wow-delay="0.2s" style="color: whitesmoke">
                        Issue medical certificates for completed appointments
                    </p>
                    <nav aria-label="breadcrumb" class="wow fadeInUp" data-wow-delay="0.3s">
                        <ol class="breadcrumb" style="background: transparent; margin: 0;">
                            <li class="breadcrumb-item">
                                <a href="<%= request.getContextPath()%>/DoctorHomepageServlet?action=dashboard" style="color: rgba(255,255,255,0.8);">Dashboard</a>
                            </li>
                            <li class="breadcrumb-item active" style="color: white;">Generate MC</li>
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

            <div class="mc-container wow fadeInUp" data-wow-delay="0.2s">
                <div class="mc-header">
                    <h3><i class="fa fa-file-medical"></i> Medical Certificate Generation</h3>
                    <p style="margin: 0; opacity: 0.9; color: white;">Select a completed appointment and fill in the medical certificate details</p>
                </div>
                
                <div class="mc-body">
                    <!-- Completed Appointments Selection -->
                    <div class="form-section">
                        <div class="section-title">
                            <i class="fa fa-calendar-check"></i> Select Completed Appointment
                        </div>
                        
                        <% if (completedAppointments != null && !completedAppointments.isEmpty()) { %>
                            <% for (Appointment appointment : completedAppointments) { %>
                                <div class="appointment-card" onclick="selectAppointment(<%= appointment.getId() %>)" id="appointment-<%= appointment.getId() %>" style="cursor: pointer;">
                                    <!-- Appointment ID Row -->
                                    <div style="margin-bottom: 15px; padding-bottom: 10px; border-bottom: 1px solid #dee2e6;">
                                        <div class="info-item">
                                            <span class="info-label" style="font-size: 1em; color: #667eea;">Appointment ID</span>
                                            <span class="info-value" style="font-size: 1.1em; font-weight: bold; color: #333;">AMC-A<%= String.format("%06d", appointment.getId()) %></span>
                                        </div>
                                    </div>
                                    
                                    <!-- Patient and Appointment Details in 3 columns -->
                                    <div class="appointment-info">
                                        <div class="info-item">
                                            <span class="info-label">Patient Name</span>
                                            <span class="info-value"><%= appointment.getCustomer().getName() %></span>
                                        </div>
                                        <div class="info-item">
                                            <span class="info-label">IC Number</span>
                                            <span class="info-value"><%= appointment.getCustomer().getIc() %></span>
                                        </div>
                                        <div class="info-item">
                                            <span class="info-label">Appointment Date</span>
                                            <span class="info-value">
                                                <% if (appointment.getAppointmentDate() != null) { %>
                                                    <%= displayFormat.format(appointment.getAppointmentDate()) %>
                                                <% } else { %>
                                                    N/A
                                                <% } %>
                                            </span>
                                        </div>
                                        <div class="info-item">
                                            <span class="info-label">Treatment</span>
                                            <span class="info-value">
                                                <%= appointment.getTreatment() != null ? appointment.getTreatment().getName() : "N/A" %>
                                            </span>
                                        </div>
                                        <div class="info-item">
                                            <span class="info-label">Gender</span>
                                            <span class="info-value"><%= appointment.getCustomer().getGender() %></span>
                                        </div>
                                        <div class="info-item">
                                            <span class="info-label">Status</span>
                                            <span class="info-value">
                                                <span class="badge badge-success">Completed</span>
                                            </span>
                                        </div>
                                    </div>
                                    
                                    <div class="text-center">
                                        <button type="button" class="btn btn-primary btn-sm" onclick="selectAppointment(<%= appointment.getId() %>)">
                                            <i class="fa fa-plus"></i> Generate MC for this Appointment
                                        </button>
                                    </div>
                                </div>
                            <% } %>
                        <% } else { %>
                            <div class="alert alert-info">
                                <i class="fa fa-info-circle"></i>
                                No completed appointments available for medical certificate generation.
                                <br><small>Only appointments marked as "completed" can have medical certificates issued.</small>
                            </div>
                        <% } %>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Medical Certificate Form Modal -->
    <div class="modal fade" id="mcModal" tabindex="-1" role="dialog" aria-labelledby="mcModalLabel">
        <div class="modal-dialog modal-lg" role="document">
            <div class="modal-content">
                <div class="modal-header" style="background: linear-gradient(45deg, #667eea 0%, #764ba2 100%); color: white;">
                    <h4 class="modal-title" id="mcModalLabel" style="color: white;">
                        <i class="fa fa-file-text-o"></i> Generate Medical Certificate
                    </h4>
                    <button type="button" class="close" data-dismiss="modal" style="color: white;">
                        <span>&times;</span>
                    </button>
                </div>
                
                <form method="post" action="<%= request.getContextPath()%>/MedicalCertificateServlet">
                    <div class="modal-body">
                        <input type="hidden" name="action" value="createMC">
                        <input type="hidden" name="appointmentId" id="selectedAppointmentId">
                        
                        <!-- Patient Information (Read-only) -->
                        <div class="patient-info-card">
                            <h5 style="color: #667eea; margin-bottom: 15px;">
                                <i class="fa fa-user"></i> Patient Information
                            </h5>
                            <div class="form-row">
                                <div class="form-group">
                                    <label>Patient Name:</label>
                                    <input type="text" class="form-control readonly-field" id="patientName" readonly>
                                </div>
                                <div class="form-group">
                                    <label>IC Number:</label>
                                    <input type="text" class="form-control readonly-field" id="patientIC" readonly>
                                </div>
                            </div>
                            <div class="form-row">
                                <div class="form-group">
                                    <label>Gender:</label>
                                    <input type="text" class="form-control readonly-field" id="patientGender" readonly>
                                </div>
                                <div class="form-group">
                                    <label>Treatment:</label>
                                    <input type="text" class="form-control readonly-field" id="treatmentName" readonly>
                                </div>
                            </div>
                        </div>
                        
                        <!-- MC Details -->
                        <div class="form-section">
                            <div class="section-title">
                                <i class="fa fa-calendar"></i> Medical Certificate Period
                            </div>
                            
                            <div class="form-row">
                                <div class="form-group">
                                    <label for="startDate">Start Date <span class="required">*</span>:</label>
                                    <input type="date" class="form-control" name="startDate" id="startDate" 
                                           value="<%= today %>" min="<%= today %>" required>
                                    <small class="text-muted">First day of medical leave</small>
                                </div>
                                <div class="form-group">
                                    <label for="endDate">End Date <span class="required">*</span>:</label>
                                    <input type="date" class="form-control" name="endDate" id="endDate" 
                                           value="<%= today %>" min="<%= today %>" required>
                                    <small class="text-muted">Last day of medical leave</small>
                                </div>
                            </div>
                        </div>
                        
                        <div class="form-section">
                            <div class="section-title">
                                <i class="fa fa-stethoscope"></i> Medical Details
                            </div>
                            
                            <div class="form-group">
                                <label for="reason">Medical Reason <span class="required">*</span>:</label>
                                <textarea class="form-control" name="reason" id="reason" rows="3" 
                                          placeholder="e.g., Acute upper respiratory tract infection, Fever, Rest advised..." required></textarea>
                                <small class="text-muted">Brief medical condition requiring rest</small>
                            </div>
                            
                            <div class="form-group">
                                <label for="additionalNotes">Additional Notes (Optional):</label>
                                <textarea class="form-control" name="additionalNotes" id="additionalNotes" rows="3" 
                                          placeholder="Any additional medical recommendations or instructions..."></textarea>
                                <small class="text-muted">Optional additional medical advice or restrictions</small>
                            </div>
                        </div>
                    </div>
                    
                    <div class="modal-footer">
                        <button type="submit" class="btn btn-generate">
                            <i class="fa fa-file-pdf-o"></i> Generate Medical Certificate
                        </button>
                        <button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <%@ include file="/includes/footer.jsp" %>
    <%@ include file="/includes/scripts.jsp" %>

    <script>
        let selectedAppointmentData = null;
        
        function selectAppointment(appointmentId) {
            // Find the appointment data
            <% if (completedAppointments != null) { %>
                <% for (Appointment appointment : completedAppointments) { %>
                    if (<%= appointment.getId() %> === appointmentId) {
                        selectedAppointmentData = {
                            id: <%= appointment.getId() %>,
                            patientName: '<%= appointment.getCustomer().getName() %>',
                            patientIC: '<%= appointment.getCustomer().getIc() %>',
                            patientGender: '<%= appointment.getCustomer().getGender() %>',
                            treatmentName: '<%= appointment.getTreatment() != null ? appointment.getTreatment().getName() : "N/A" %>'
                        };
                    }
                <% } %>
            <% } %>
            
            if (selectedAppointmentData) {
                // Populate modal fields
                document.getElementById('selectedAppointmentId').value = selectedAppointmentData.id;
                document.getElementById('patientName').value = selectedAppointmentData.patientName;
                document.getElementById('patientIC').value = selectedAppointmentData.patientIC;
                document.getElementById('patientGender').value = selectedAppointmentData.patientGender;
                document.getElementById('treatmentName').value = selectedAppointmentData.treatmentName;
                
                // Clear form fields
                document.getElementById('reason').value = '';
                document.getElementById('additionalNotes').value = '';
                
                // Show modal
                $('#mcModal').modal('show');
            }
        }
        
        // Auto-update end date when start date changes
        document.getElementById('startDate').addEventListener('change', function() {
            const startDate = this.value;
            const endDateField = document.getElementById('endDate');
            
            if (startDate) {
                // Set minimum end date to start date
                endDateField.min = startDate;
                
                // If end date is before start date, update it
                if (endDateField.value < startDate) {
                    endDateField.value = startDate;
                }
            }
        });
        
       
        // Form validation
        document.querySelector('form').addEventListener('submit', function(e) {
            const startDate = new Date(document.getElementById('startDate').value);
            const endDate = new Date(document.getElementById('endDate').value);
            const reason = document.getElementById('reason').value.trim();
            
            if (endDate < startDate) {
                e.preventDefault();
                alert('End date cannot be before start date.');
                return false;
            }
            
            if (!reason) {
                e.preventDefault();
                alert('Medical reason is required.');
                return false;
            }
            
            // Confirm before submission
            if (!confirm('Are you sure you want to generate this medical certificate?')) {
                e.preventDefault();
                return false;
            }
        });
    </script>
</body>
</html>

<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.text.DecimalFormat" %>
<%@ page import="model.Customer" %>
<%@ page import="model.Doctor" %>
<%@ page import="model.Appointment" %>
<%@ page import="model.Feedback" %>
<%@ page import="java.util.Date" %>
<%
    Doctor doctor = (Doctor) session.getAttribute("doctor");
    if (doctor == null) {
        response.sendRedirect("../login.jsp");
        return;
    }
    
    List<Customer> patients = (List<Customer>) request.getAttribute("patients");
    Customer selectedPatient = (Customer) request.getAttribute("selectedPatient");
    List<Appointment> patientAppointments = (List<Appointment>) request.getAttribute("patientAppointments");
    List<Feedback> patientFeedbacks = (List<Feedback>) request.getAttribute("patientFeedbacks");
    String searchQuery = (String) request.getAttribute("searchQuery");
    
    SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMM yyyy");
    SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm");
    DecimalFormat df = new DecimalFormat("#.#");
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Patient Records - AMC Healthcare System</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manager-homepage.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manage-staff.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/doctor-ratings.css">

        <style>
            .patient-card {
                border: 1px solid #ddd;
                border-radius: 8px;
                padding: 15px;
                margin-bottom: 15px;
                background: white;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                transition: transform 0.2s ease, box-shadow 0.2s ease;
            }

            .patient-card:hover {
                transform: translateY(-2px);
                box-shadow: 0 4px 8px rgba(0,0,0,0.15);
            }

            .patient-header {
                display: flex;
                justify-content: between;
                align-items: center;
                margin-bottom: 10px;
            }

            .patient-avatar {
                width: 50px;
                height: 50px;
                border-radius: 50%;
                background: linear-gradient(135deg, #007bff 0%, #0056b3 100%);
                display: flex;
                align-items: center;
                justify-content: center;
                color: white;
                font-weight: bold;
                font-size: 1.2em;
                margin-right: 15px;
            }

            .patient-info h5 {
                margin: 0;
                color: #333;
                font-weight: 600;
            }

            .patient-details {
                color: #666;
                font-size: 0.9em;
                margin-top: 5px;
            }

            .medical-history-section {
                background: #f8f9fa;
                border-radius: 8px;
                padding: 20px;
                margin-top: 20px;
            }

            .appointment-history-item {
                border-left: 4px solid #007bff;
                background: white;
                padding: 15px;
                margin-bottom: 15px;
                border-radius: 0 8px 8px 0;
                box-shadow: 0 2px 4px rgba(0,0,0,0.05);
            }

            .appointment-date {
                font-weight: bold;
                color: #007bff;
                margin-bottom: 5px;
            }

            .treatment-name {
                font-size: 1.1em;
                font-weight: 600;
                color: #333;
                margin-bottom: 8px;
            }

            .status-badge {
                padding: 4px 12px;
                border-radius: 20px;
                font-size: 12px;
                font-weight: bold;
                text-transform: uppercase;
            }

            .status-completed {
                background-color: #28a745;
                color: white;
            }

            .status-approved {
                background-color: #17a2b8;
                color: white;
            }

            .status-pending {
                background-color: #ffc107;
                color: #333;
            }

            .status-cancelled {
                background-color: #dc3545;
                color: white;
            }

            .patient-stats {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
                gap: 15px;
                margin-bottom: 20px;
            }

            .stat-item {
                text-align: center;
                background: white;
                padding: 15px;
                border-radius: 8px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            }

            .stat-number {
                font-size: 1.5em;
                font-weight: bold;
                color: #007bff;
                display: block;
            }

            .stat-label {
                font-size: 0.8em;
                color: #666;
                text-transform: uppercase;
                letter-spacing: 0.5px;
            }

            .no-records {
                text-align: center;
                padding: 40px;
                color: #999;
            }

            .patient-info-card {
                background: white;
                border-radius: 10px;
                padding: 25px;
                margin-bottom: 30px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                border-left: 4px solid #007bff;
            }

            .info-group {
                display: flex;
                flex-direction: column;
                gap: 12px;
            }

            .info-item {
                display: flex;
                align-items: center;
                gap: 10px;
                padding: 8px 0;
                border-bottom: 1px solid #f0f0f0;
            }

            .info-item:last-child {
                border-bottom: none;
            }

            .info-icon {
                color: #007bff;
                width: 16px;
                text-align: center;
                flex-shrink: 0;
            }

            .info-label {
                font-weight: 600;
                color: #333;
                min-width: 80px;
                flex-shrink: 0;
            }

            .info-value {
                color: #555;
                word-break: break-word;
                flex: 1;
            }

            .back-to-list {
                background: #6c757d;
                color: white;
                border: none;
                padding: 8px 15px;
                border-radius: 5px;
                text-decoration: none;
                font-size: 0.9em;
            }

            .back-to-list:hover {
                background: #5a6268;
                color: white;
                text-decoration: none;
            }

            @media (max-width: 768px) {
                .patient-header {
                    flex-direction: column;
                    text-align: center;
                }

                .patient-avatar {
                    margin-right: 0;
                    margin-bottom: 10px;
                }

                .patient-info-card {
                    margin: 15px 0;
                    padding: 20px 15px;
                }

                .info-group {
                    margin-top: 20px !important;
                }

                .info-item {
                    flex-direction: column;
                    align-items: flex-start;
                    gap: 5px;
                    padding: 10px 0;
                }

                .info-label {
                    min-width: auto;
                    font-size: 0.9em;
                }

                .info-value {
                    font-size: 0.95em;
                    margin-left: 20px;
                }
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
                            <i class="fa fa-user-md" style="color:white"></i>
                            <span style="color:white">Patient Records</span>
                        </h1>
                        <p class="lead wow fadeInUp" data-wow-delay="0.2s" style="color: whitesmoke">
                            <% if (selectedPatient != null) { %>
                            Medical records and history for <%= selectedPatient.getName() %>
                            <% } else { %>
                            Access and manage your patient medical records
                            <% } %>
                        </p>
                        <nav aria-label="breadcrumb" class="wow fadeInUp" data-wow-delay="0.3s">
                            <ol class="breadcrumb" style="background: transparent; margin: 0;">
                                <li class="breadcrumb-item">
                                    <a href="<%= request.getContextPath()%>/DoctorHomepageServlet" style="color: rgba(255,255,255,0.8);">Dashboard</a>
                                </li>
                                <li class="breadcrumb-item">
                                    <a href="<%= request.getContextPath()%>/DoctorServlet?action=patientRecords" style="color: rgba(255,255,255,0.8);">Patient Records</a>
                                </li>
                                <% if (selectedPatient != null) { %>
                                <li class="breadcrumb-item active" style="color: white;"><%= selectedPatient.getName() %></li>
                                <% } else { %>
                                <li class="breadcrumb-item active" style="color: white;">All Patients</li>
                                <% } %>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>
        </section>

        <!-- MAIN CONTENT -->
        <section style="padding: 40px 0; background: #f5f5f5;">
            <div class="container">
                <% String error = (String) request.getAttribute("error"); %>
                <% if (error != null) { %>
                <div class="alert alert-danger alert-dismissible">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <i class="fa fa-exclamation-triangle"></i> <%= error %>
                </div>
                <% } %>

                <% if (selectedPatient != null) { %>
                <!-- SELECTED PATIENT DETAILS -->
                <div class="row">
                    <div class="col-md-12">
                        <a href="<%= request.getContextPath()%>/DoctorServlet?action=patientRecords" class="back-to-list">
                            <i class="fa fa-arrow-left"></i> Back to Patient List
                        </a>
                    </div>
                </div>
                
                <div class="medical-history-section wow fadeInUp" data-wow-delay="0.2s">
                        <div class="patient-info-card">
                            <div class="row">
                                <div class="col-md-6">
                                    <h3 style="margin: 0 0 15px 0; color: #007bff;">
                                        <i class="fa fa-user"></i> <%= selectedPatient.getName() %>
                                    </h3>
                                    <div class="info-group">
                                        <div class="info-item">
                                            <i class="fa fa-envelope info-icon"></i>
                                            <span class="info-label">Email:</span>
                                            <span class="info-value"><%= selectedPatient.getEmail() %></span>
                                        </div>
                                        <div class="info-item">
                                            <i class="fa fa-phone info-icon"></i>
                                            <span class="info-label">Phone:</span>
                                            <span class="info-value"><%= selectedPatient.getPhone() != null ? selectedPatient.getPhone() : "N/A" %></span>
                                        </div>
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <div class="info-group" style="margin-top: 45px;">
                                        <div class="info-item">
                                            <i class="fa fa-id-card info-icon"></i>
                                            <span class="info-label">IC Number:</span>
                                            <span class="info-value"><%= selectedPatient.getIc() != null ? selectedPatient.getIc() : "N/A" %></span>
                                        </div>
                                        <div class="info-item">
                                            <i class="fa fa-birthday-cake info-icon"></i>
                                            <span class="info-label">Date of Birth:</span>
                                            <span class="info-value"><%= selectedPatient.getDob() != null ? dateFormat.format(selectedPatient.getDob()) : "N/A" %></span>
                                        </div>
                                        <div class="info-item">
                                            <i class="fa fa-venus-mars info-icon"></i>
                                            <span class="info-label">Gender:</span>
                                            <span class="info-value"><%= selectedPatient.getGender() != null ? selectedPatient.getGender() : "N/A" %></span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                    <!-- Patient Statistics -->
                    <div class="patient-stats">
                        <div class="stat-item">
                            <span class="stat-number"><%= patientAppointments != null ? patientAppointments.size() : 0 %></span>
                            <span class="stat-label">Total Visits</span>
                        </div>
                        <div class="stat-item">
                            <%
                                int completedVisits = 0;
                                if (patientAppointments != null) {
                                    for (Appointment apt : patientAppointments) {
                                        if ("completed".equals(apt.getStatus())) {
                                            completedVisits++;
                                        }
                                    }
                                }
                            %>
                            <span class="stat-number"><%= completedVisits %></span>
                            <span class="stat-label">Completed</span>
                        </div>
                        <div class="stat-item">
                            <span class="stat-number"><%= patientFeedbacks != null ? patientFeedbacks.size() : 0 %></span>
                            <span class="stat-label">Feedback Given</span>
                        </div>
                        <div class="stat-item">
                            <%
                                Date lastVisit = null;
                                if (patientAppointments != null && !patientAppointments.isEmpty()) {
                                    for (Appointment apt : patientAppointments) {
                                        if (apt.getAppointmentDate() != null) {
                                            if (lastVisit == null || apt.getAppointmentDate().after(lastVisit)) {
                                                lastVisit = apt.getAppointmentDate();
                                            }
                                        }
                                    }
                                }
                            %>
                            <span class="stat-number" style="font-size: 0.9em;">
                                <%= lastVisit != null ? dateFormat.format(lastVisit) : "Never" %>
                            </span>
                            <span class="stat-label">Last Visit</span>
                        </div>
                    </div>

                    <!-- Medical History -->
                    <h4><i class="fa fa-history"></i> Medical History</h4>
                    <% if (patientAppointments != null && !patientAppointments.isEmpty()) { %>
                    <%
                        // Sort appointments by date (newest first)
                        java.util.Collections.sort(patientAppointments, new java.util.Comparator<Appointment>() {
                            public int compare(Appointment a1, Appointment a2) {
                                if (a1.getAppointmentDate() == null) return 1;
                                if (a2.getAppointmentDate() == null) return -1;
                                return a2.getAppointmentDate().compareTo(a1.getAppointmentDate());
                            }
                        });
                    %>
                    
                    <% for (Appointment appointment : patientAppointments) { %>
                    <div class="appointment-history-item">
                        <div class="row">
                            <div class="col-md-3">
                                <div class="appointment-date">
                                    <i class="fa fa-calendar"></i> 
                                    <%= appointment.getAppointmentDate() != null ? dateFormat.format(appointment.getAppointmentDate()) : "N/A" %>
                                </div>
                                <div style="color: #666; font-size: 0.9em;">
                                    <i class="fa fa-clock-o"></i> 
                                    <%= appointment.getAppointmentTime() != null ? timeFormat.format(appointment.getAppointmentTime()) : "N/A" %>
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="treatment-name">
                                    <i class="fa fa-stethoscope"></i> 
                                    <%= appointment.getTreatment() != null ? appointment.getTreatment().getName() : "General Consultation" %>
                                </div>
                                <span class="status-badge status-<%= appointment.getStatus().toLowerCase() %>">
                                    <%= appointment.getStatus().toUpperCase() %>
                                </span>
                            </div>
                            <div class="col-md-5">
                                <% if (appointment.getDocMessage() != null && !appointment.getDocMessage().trim().isEmpty()) { %>
                                <div style="background: #e3f2fd; padding: 10px; border-radius: 5px; margin-bottom: 8px;">
                                    <strong style="color: #1976d2;">Doctor's Notes:</strong><br>
                                    <span style="color: #333;"><%= appointment.getDocMessage() %></span>
                                </div>
                                <% } %>
                                
                                <% if (appointment.getCustMessage() != null && !appointment.getCustMessage().trim().isEmpty()) { %>
                                <div style="background: #f3e5f5; padding: 10px; border-radius: 5px;">
                                    <strong style="color: #7b1fa2;">Patient's Concern:</strong><br>
                                    <span style="color: #333;"><%= appointment.getCustMessage() %></span>
                                </div>
                                <% } %>
                            </div>
                        </div>
                    </div>
                    <% } %>
                    <% } else { %>
                    <div class="no-records">
                        <i class="fa fa-file-text-o"></i>
                        <h4>No Medical History Found</h4>
                        <p>This patient hasn't had any appointments with you yet.</p>
                    </div>
                    <% } %>
                </div>

                <% } else { %>
                <!-- PATIENT LIST -->
                <div class="search-filter-section wow fadeInUp" data-wow-delay="0.2s">
                    <h3><i class="fa fa-search"></i> Search My Patients</h3>

                    <form method="GET" action="<%= request.getContextPath()%>/DoctorServlet" class="search-form">
                        <input type="hidden" name="action" value="patientRecords">
                        
                        <div class="form-row">
                            <div class="form-group">
                                <label for="searchQuery">Search by Name, Email, or IC</label>
                                <input type="text" class="form-control" id="searchQuery" name="searchQuery" 
                                       placeholder="Enter patient name, email, or IC..." 
                                       value="<%= searchQuery != null ? searchQuery : "" %>">
                            </div>
                        </div>
                        
                        <div class="form-group">
                            <button type="submit" class="btn btn-primary">
                                <i class="fa fa-search"></i> Search
                            </button>
                            <a href="<%= request.getContextPath()%>/DoctorServlet?action=patientRecords" class="btn btn-secondary">
                                <i class="fa fa-refresh"></i> Clear
                            </a>
                        </div>
                    </form>
                </div>

                <!-- PATIENTS LIST -->
                <div class="wow fadeInUp" data-wow-delay="0.3s">
                    <h3><i class="fa fa-users"></i> My Patients
                        <% if (patients != null) { %>
                        <span class="badge badge-primary"><%= patients.size() %></span>
                        <% } %>
                    </h3>

                    <% if (patients != null && !patients.isEmpty()) { %>
                    <%
                        // Get all appointments for visit counting
                        List<Appointment> allAppointments = (List<Appointment>) request.getAttribute("allDoctorAppointments");
                        if (allAppointments == null) {
                            allAppointments = new java.util.ArrayList<Appointment>();
                        }
                    %>
                    <div class="row">
                        <% for (Customer patient : patients) { %>
                        <%
                            // Count visits for this patient
                            int visitCount = 0;
                            int completedVisits = 0;
                            Date lastVisitDate = null;
                            
                            for (Appointment apt : allAppointments) {
                                if (apt.getCustomer() != null && apt.getCustomer().getId() == patient.getId()) {
                                    visitCount++;
                                    if ("completed".equals(apt.getStatus())) {
                                        completedVisits++;
                                    }
                                    if (apt.getAppointmentDate() != null) {
                                        if (lastVisitDate == null || apt.getAppointmentDate().after(lastVisitDate)) {
                                            lastVisitDate = apt.getAppointmentDate();
                                        }
                                    }
                                }
                            }
                        %>
                        <div class="col-md-6 col-lg-4">
                            <div class="patient-card">
                                <div class="patient-header">
                                    <div class="patient-avatar">
                                        <%= patient.getName().substring(0, 1).toUpperCase() %>
                                    </div>
                                    <div class="patient-info">
                                        <h5><%= patient.getName() %>
                                            <% if (visitCount > 1) { %>
                                            <span class="badge badge-info" style="font-size: 0.7em; margin-left: 5px;">
                                                <%= visitCount %> visits
                                            </span>
                                            <% } %>
                                        </h5>
                                        <div class="patient-details">
                                            <i class="fa fa-envelope"></i> <%= patient.getEmail() %><br>
                                            <% if (patient.getPhone() != null) { %>
                                            <i class="fa fa-phone"></i> <%= patient.getPhone() %><br>
                                            <% } %>
                                            <% if (patient.getIc() != null) { %>
                                            <i class="fa fa-id-card"></i> <%= patient.getIc() %><br>
                                            <% } %>
                                            <% if (lastVisitDate != null) { %>
                                            <small class="text-muted">
                                                <i class="fa fa-clock-o"></i> Last visit: <%= dateFormat.format(lastVisitDate) %>
                                            </small>
                                            <% } %>
                                        </div>
                                    </div>
                                </div>
                                
                                <% if (visitCount > 0) { %>
                                <div style="margin-top: 10px; margin-bottom: 15px;">
                                    <div class="row text-center">
                                        <div class="col-4">
                                            <small class="text-muted">Total</small><br>
                                            <strong class="text-primary"><%= visitCount %></strong>
                                        </div>
                                        <div class="col-4">
                                            <small class="text-muted">Completed</small><br>
                                            <strong class="text-success"><%= completedVisits %></strong>
                                        </div>
                                        <div class="col-4">
                                            <small class="text-muted">Completion Rate</small><br>
                                            <strong class="text-info"><%= visitCount > 0 ? Math.round((double)completedVisits/visitCount*100) : 0 %>%</strong>
                                        </div>
                                    </div>
                                </div>
                                <% } %>
                                
                                <div style="margin-top: 15px;">
                                    <a href="<%= request.getContextPath()%>/DoctorServlet?action=patientRecords&customerId=<%= patient.getId() %>" 
                                       class="btn btn-primary btn-sm btn-block">
                                        <i class="fa fa-eye"></i> View Medical Records
                                    </a>
                                </div>
                            </div>
                        </div>
                        <% } %>
                    </div>
                    <% } else { %>
                    <div class="no-records">
                        <i class="fa fa-users"></i>
                        <h4>No Patients Found</h4>
                        <% if (searchQuery != null && !searchQuery.trim().isEmpty()) { %>
                        <p>No patients found matching "<%= searchQuery %>". Try adjusting your search criteria.</p>
                        <% } else { %>
                        <p>You haven't had any patients yet. Patients will appear here after they book appointments with you.</p>
                        <% } %>
                    </div>
                    <% } %>
                </div>
                <% } %>
            </div>
        </section>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>

        <script>
            $(document).ready(function() {
                // Add animations to patient cards
                $('.patient-card').hover(
                    function() {
                        $(this).addClass('shadow-lg');
                    },
                    function() {
                        $(this).removeClass('shadow-lg');
                    }
                );

                // Auto-focus on search field
                $('#searchQuery').focus();
            });
        </script>
    </body>
</html>

<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.Date" %>
<%@ page import="java.util.Calendar" %>
<%@ page import="model.Appointment" %>
<%@ page import="model.Doctor" %>
<%@ page import="model.Treatment" %>
<%@ page import="model.Customer" %>

<%
    // Check if user is logged in
    Customer loggedInCustomer = (Customer) session.getAttribute("customer");

    if (loggedInCustomer == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    } else {
        System.out.println(loggedInCustomer.getName() + " logged in succesfully!");
    }

    // Retrieve the list of doctors and treatments from the request attributes
    List<Doctor> doctorList = (List<Doctor>) request.getAttribute("doctorList");
    List<Treatment> treatmentList = (List<Treatment>) request.getAttribute("treatmentList");
    
    // Retrieve appointment reminder data with comprehensive validation
    List<Appointment> upcomingAppointments = (List<Appointment>) request.getAttribute("upcomingAppointments");
    List<Appointment> urgentReminders = (List<Appointment>) request.getAttribute("urgentReminders");
    List<Appointment> overdueAppointments = (List<Appointment>) request.getAttribute("overdueAppointments");
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <title>APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
    </head>


    <body id="top" data-spy="scroll" data-target=".navbar-collapse" data-offset="50">

        <%--<%@ include file="/includes/preloader.jsp" %>--%>
        <%@ include file="/includes/header.jsp" %>
        <%@ include file="/includes/navbar.jsp" %>

        <!-- HOME -->
        <section id="home" class="slider" data-stellar-background-ratio="0.5">
            <div class="container">
                <div class="row">
                    <div class="owl-carousel owl-theme">
                        <div class="item item-first">
                            <div class="caption">
                                <div class="col-md-offset-1 col-md-10">
                                    <h3>Let's make your life happier</h3>
                                    <h1>Healthy Living</h1>
                                    <a href="#team" class="section-btn btn btn-default smoothScroll">Meet Our
                                        Doctors</a>
                                </div>
                            </div>
                        </div>

                        <div class="item item-second">
                            <div class="caption">
                                <div class="col-md-offset-1 col-md-10">
                                    <h3>Learn more about APU Medical Center</h3>
                                    <h1>Our Story</h1>
                                    <a href="#about" class="section-btn btn btn-default btn-gray smoothScroll">More
                                        About Us</a>
                                </div>
                            </div>
                        </div>

                        <div class="item item-third">
                            <div class="caption">
                                <div class="col-md-offset-1 col-md-10">
                                    <h3>Patient First and Foremost</h3>
                                    <h1>Health Care for All</h1>
                                    <a href="#treatments"
                                       class="section-btn btn btn-default btn-blue smoothScroll">More Treatment
                                        Services</a>
                                </div>
                            </div>
                        </div>
                    </div>

                </div>
            </div>
        </section>

        <!-- APPOINTMENT REMINDERS -->
        <%
            boolean hasAppointments = (upcomingAppointments != null && !upcomingAppointments.isEmpty()) || 
                                    (overdueAppointments != null && !overdueAppointments.isEmpty());
            
            // Debug logging for JSP
            System.out.println("=== JSP DEBUGGING ===");
            System.out.println("upcomingAppointments: " + (upcomingAppointments != null ? upcomingAppointments.size() : "null"));
            System.out.println("overdueAppointments: " + (overdueAppointments != null ? overdueAppointments.size() : "null"));
            System.out.println("hasAppointments: " + hasAppointments);
            System.out.println("====================");
            
            if (hasAppointments) {
        %>
        <section class="reminder-section">
            <div class="container">
                <div class="row">
                    <div class="col-md-12">
                        <div class="section-title wow fadeInUp" data-wow-delay="0.1s">
                            <h2 style="color: #333;">
                                <i class="fa fa-bell" style="color: #667eea;"></i> Appointment Reminders
                            </h2>
                            <p style="color: #666; margin-top: 15px;">
                                Don't miss your upcoming appointments
                            </p>
                        </div>
                    </div>
                </div>
                
                <div class="row">
                    <%
                        SimpleDateFormat dateFormat = new SimpleDateFormat("EEEE, MMMM dd, yyyy");
                        SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm");
                        Date today = new Date();
                        Calendar cal = Calendar.getInstance();
                        cal.setTime(today);
                        cal.set(Calendar.HOUR_OF_DAY, 0);
                        cal.set(Calendar.MINUTE, 0);
                        cal.set(Calendar.SECOND, 0);
                        cal.set(Calendar.MILLISECOND, 0);
                        Date todayStart = cal.getTime();
                        
                        cal.add(Calendar.DAY_OF_MONTH, 2);
                        Date urgentDate = cal.getTime();
                        
                        // Separate appointments into different categories
                        java.util.List<Appointment> overdueAppointmentsList = new java.util.ArrayList<Appointment>();
                        java.util.List<Appointment> rescheduleAppointments = new java.util.ArrayList<Appointment>();
                        java.util.List<Appointment> regularAppointments = new java.util.ArrayList<Appointment>();
                        
                        // Process overdue appointments (highest priority - separate from reschedule)
                        if (overdueAppointments != null) {
                            overdueAppointmentsList.addAll(overdueAppointments);
                        }
                        
                        // Process upcoming appointments and categorize them
                        if (upcomingAppointments != null) {
                            for (Appointment appointment : upcomingAppointments) {
                                // Skip overdue appointments (already processed above)
                                if (appointment.getAppointmentDate().before(todayStart)) {
                                    continue;
                                }
                                
                                String status = appointment.getStatus().trim().toLowerCase();
                                if ("reschedule".equals(status)) {
                                    rescheduleAppointments.add(appointment);
                                } else if ("approved".equals(status) || "confirmed".equals(status)) {
                                    regularAppointments.add(appointment);
                                }
                            }
                        }
                    %>
                    
                    <!-- Left Column: Overdue and Reschedule Appointments -->
                    <div class="col-md-6">
                        <%
                            double leftDelay = 0.2;
                            
                            // First display overdue appointments (highest priority)
                            for (Appointment appointment : overdueAppointmentsList) {
                        %>
                        <div class="reminder-card reminder-overdue wow fadeInUp" data-wow-delay="<%= leftDelay%>s">
                            <div class="reminder-icon">
                                <i class="fa fa-exclamation-circle" style="color: #dc3545; animation: pulse 1.5s infinite;"></i>
                                <span style="font-size: 0.9em; color: #dc3545; font-weight: bold; margin-left: 10px;">
                                    OVERDUE APPOINTMENT
                                </span>
                            </div>
                            <div style="font-size: 0.85em; color: #666; margin-bottom: 10px;">
                                <i class="fa fa-id-card-o" style="margin-right: 5px;"></i>
                                <strong>Appointment ID:</strong> #<%= appointment.getId()%>
                            </div>
                            <div class="reminder-date" style="color: #dc3545;">
                                <%= dateFormat.format(appointment.getAppointmentDate())%>
                                <% if (appointment.getAppointmentTime() != null) { %>
                                at <%= timeFormat.format(appointment.getAppointmentTime())%>
                                <% } %>
                                <span style="background: #dc3545; color: white; padding: 3px 8px; border-radius: 12px; font-size: 0.8em; margin-left: 10px;">
                                    OVERDUE
                                </span>
                            </div>
                            <div class="reminder-details">
                                <div class="reminder-treatment">
                                    <i class="fa fa-stethoscope"></i>
                                    <%= appointment.getTreatment() != null ? appointment.getTreatment().getName() : "Treatment N/A"%>
                                </div>
                                <div class="reminder-doctor">
                                    <i class="fa fa-user-md"></i>
                                    Dr. <%= appointment.getDoctor() != null ? appointment.getDoctor().getName() : "To be assigned"%>
                                </div>
                                <div style="background: rgba(220, 53, 69, 0.1); padding: 12px; border-radius: 8px; margin-top: 10px; font-size: 0.9em;">
                                    <i class="fa fa-warning" style="color: #dc3545;"></i>
                                    <strong style="color: #dc3545;">This appointment is overdue!</strong> Please reschedule immediately or contact us.
                                </div>
                                <% if (appointment.getStaffMessage() != null && !appointment.getStaffMessage().trim().isEmpty()) { %>
                                <div style="background: rgba(102, 126, 234, 0.1); padding: 10px; border-radius: 8px; margin-top: 10px; font-size: 0.9em;">
                                    <i class="fa fa-info-circle" style="color: #667eea;"></i>
                                    <strong>Staff Note:</strong> <%= appointment.getStaffMessage()%>
                                </div>
                                <% } %>
                            </div>
                            <div class="reminder-actions">
                                <a href="<%= request.getContextPath()%>/AppointmentServlet?action=history&status=overdue" class="reminder-btn btn-view">
                                    <i class="fa fa-eye"></i> View All Overdue
                                </a>
                                <a href="<%= request.getContextPath()%>/AppointmentServlet?action=reschedule&id=<%= appointment.getId()%>" class="reminder-btn" style="background: #dc3545; color: white;">
                                    <i class="fa fa-calendar"></i> Reschedule Now
                                </a>
                            </div>
                        </div>
                        <%
                                leftDelay += 0.15;
                            }
                            
                            // Then display reschedule appointments
                            for (Appointment appointment : rescheduleAppointments) {
                        %>
                        <div class="reminder-card reminder-reschedule wow fadeInUp" data-wow-delay="<%= leftDelay%>s">
                            <div class="reminder-icon">
                                <i class="fa fa-refresh" style="color: #ffc107; animation: spin 2s linear infinite;"></i>
                                <span style="font-size: 0.9em; color: #ffc107; font-weight: bold; margin-left: 10px;">
                                    RESCHEDULE REQUIRED
                                </span>
                            </div>
                            <div style="font-size: 0.85em; color: #666; margin-bottom: 10px;">
                                <i class="fa fa-id-card-o" style="margin-right: 5px;"></i>
                                <strong>Appointment ID:</strong> #<%= appointment.getId()%>
                            </div>
                            <div class="reminder-date" style="color: #ffc107;">
                                <%= dateFormat.format(appointment.getAppointmentDate())%>
                                <% if (appointment.getAppointmentTime() != null) { %>
                                at <%= timeFormat.format(appointment.getAppointmentTime())%>
                                <% } %>
                                <span style="background: #ffc107; color: #333; padding: 3px 8px; border-radius: 12px; font-size: 0.8em; margin-left: 10px;">
                                    NEEDS RESCHEDULE
                                </span>
                            </div>
                            <div class="reminder-details">
                                <div class="reminder-treatment">
                                    <i class="fa fa-stethoscope"></i>
                                    <%= appointment.getTreatment() != null ? appointment.getTreatment().getName() : "Treatment N/A"%>
                                </div>
                                <div class="reminder-doctor">
                                    <i class="fa fa-user-md"></i>
                                    Dr. <%= appointment.getDoctor() != null ? appointment.getDoctor().getName() : "To be assigned"%>
                                </div>
                                <div style="background: rgba(255, 193, 7, 0.1); padding: 12px; border-radius: 8px; margin-top: 10px; font-size: 0.9em;">
                                    <i class="fa fa-info-circle" style="color: #ffc107;"></i>
                                    <strong style="color: #ffc107;">Reschedule Requested:</strong> Please select a new date and time for your appointment.
                                </div>
                                <% if (appointment.getStaffMessage() != null && !appointment.getStaffMessage().trim().isEmpty()) { %>
                                <div style="background: rgba(102, 126, 234, 0.1); padding: 10px; border-radius: 8px; margin-top: 10px; font-size: 0.9em;">
                                    <i class="fa fa-info-circle" style="color: #667eea;"></i>
                                    <strong>Staff Note:</strong> <%= appointment.getStaffMessage()%>
                                </div>
                                <% } %>
                            </div>
                            <div class="reminder-actions">
                                <a href="<%= request.getContextPath()%>/AppointmentServlet?action=history&status=reschedule" class="reminder-btn btn-view">
                                    <i class="fa fa-eye"></i> View All Reschedule
                                </a>
                                <a href="<%= request.getContextPath()%>/AppointmentServlet?action=reschedule&id=<%= appointment.getId()%>" class="reminder-btn btn-reschedule">
                                    <i class="fa fa-calendar"></i> Reschedule
                                </a>
                            </div>
                        </div>
                        <%
                                leftDelay += 0.15;
                            }
                        %>
                    </div>
                    
                    <!-- Right Column: Approved Appointments -->
                    <div class="col-md-6">
                        <%
                            double rightDelay = 0.3;
                            
                            for (Appointment appointment : regularAppointments) {
                        %>
                        <div class="reminder-card reminder-upcoming wow fadeInUp" data-wow-delay="<%= rightDelay%>s">
                            <div class="reminder-icon">
                                <i class="fa fa-calendar-check-o"></i>
                                <span style="font-size: 0.9em; color: #28a745; font-weight: bold; margin-left: 10px;">
                                    UPCOMING APPOINTMENT
                                </span>
                            </div>
                            <div style="font-size: 0.85em; color: #666; margin-bottom: 10px;">
                                <i class="fa fa-id-card-o" style="margin-right: 5px;"></i>
                                <strong>Appointment ID:</strong> #<%= appointment.getId()%>
                            </div>
                            <div class="reminder-date" style="color: #667eea;">
                                <%= dateFormat.format(appointment.getAppointmentDate())%>
                                <% if (appointment.getAppointmentTime() != null) { %>
                                at <%= timeFormat.format(appointment.getAppointmentTime())%>
                                <% } %>
                            </div>
                            <div class="reminder-details">
                                <div class="reminder-treatment">
                                    <i class="fa fa-stethoscope"></i>
                                    <%= appointment.getTreatment() != null ? appointment.getTreatment().getName() : "Treatment N/A"%>
                                </div>
                                <div class="reminder-doctor">
                                    <i class="fa fa-user-md"></i>
                                    Dr. <%= appointment.getDoctor() != null ? appointment.getDoctor().getName() : "To be assigned"%>
                                </div>
                                <% if (appointment.getStaffMessage() != null && !appointment.getStaffMessage().trim().isEmpty()) { %>
                                <div style="background: rgba(102, 126, 234, 0.1); padding: 10px; border-radius: 8px; margin-top: 10px; font-size: 0.9em;">
                                    <i class="fa fa-info-circle" style="color: #667eea;"></i>
                                    <strong>Staff Note:</strong> <%= appointment.getStaffMessage()%>
                                </div>
                                <% } %>
                            </div>
                            <div class="reminder-actions">
                                <a href="<%= request.getContextPath()%>/AppointmentServlet?action=history&status=approved" class="reminder-btn btn-view">
                                    <i class="fa fa-eye"></i> View All Approved
                                </a>
                                <a href="<%= request.getContextPath()%>/AppointmentServlet?action=reschedule&id=<%= appointment.getId()%>" class="reminder-btn btn-reschedule">
                                    <i class="fa fa-calendar"></i> Reschedule
                                </a>
                            </div>
                        </div>
                        <%
                                rightDelay += 0.15;
                            }
                        %>
                    </div>
                </div>
                
                <!-- Quick Actions for Appointments -->
                <div class="row" style="margin-top: 30px;">
                    <div class="col-md-12 text-center">
                        <div style="margin-bottom: 15px;">
                            <h4 style="color: #333; margin-bottom: 20px;">
                                <i class="fa fa-filter" style="color: #667eea;"></i> Quick Filters
                            </h4>
                        </div>
                        <div style="margin-bottom: 20px;">
                            <a href="<%= request.getContextPath()%>/AppointmentServlet?action=history&status=overdue" class="section-btn btn" style="background: #dc3545; color: white; margin: 5px;">
                                <i class="fa fa-exclamation-circle"></i> View Overdue
                            </a>
                            <a href="<%= request.getContextPath()%>/AppointmentServlet?action=history&status=reschedule" class="section-btn btn" style="background: #ffc107; color: #333; margin: 5px;">
                                <i class="fa fa-refresh"></i> View Reschedule Required
                            </a>
                            <a href="<%= request.getContextPath()%>/AppointmentServlet?action=history&status=approved" class="section-btn btn" style="background: #28a745; color: white; margin: 5px;">
                                <i class="fa fa-check-circle"></i> View Approved
                            </a>
                            <a href="<%= request.getContextPath()%>/AppointmentServlet?action=history&status=completed" class="section-btn btn" style="background: #6c757d; color: white; margin: 5px;">
                                <i class="fa fa-check"></i> View Completed
                            </a>
                            <a href="<%= request.getContextPath()%>/AppointmentServlet?action=history&status=pending" class="section-btn btn" style="background: #17a2b8; color: white; margin: 5px;">
                                <i class="fa fa-clock-o"></i> View Pending
                            </a>
                        </div>
                        <div>
                            <a href="<%= request.getContextPath()%>/AppointmentServlet?action=history&status=all" class="section-btn btn btn-default" style="margin: 0 10px;">
                                <i class="fa fa-history"></i> View All Appointments
                            </a>
                            <a href="<%= request.getContextPath()%>/AppointmentServlet?action=book" class="section-btn btn btn-success" style="margin: 0 10px;">
                                <i class="fa fa-plus"></i> Book New Appointment
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </section>
        <%
            } else {
        %>
        <!-- No Appointments Message (Optional - can be hidden) -->
        <section class="reminder-section" style="padding: 40px 0;">
            <div class="container">
                <div class="row">
                    <div class="col-md-12">
                        <div class="no-appointments wow fadeInUp" data-wow-delay="0.1s">
                            <i class="fa fa-calendar-o"></i>
                            <h3>No Upcoming Appointments</h3>
                            <p>You don't have any approved appointments in the next week.</p>
                            <div style="margin-top: 30px;">
                                <a href="<%= request.getContextPath()%>/AppointmentServlet?action=book" class="section-btn btn btn-default" style="margin: 10px;">
                                    <i class="fa fa-plus"></i> Book Your First Appointment
                                </a>
                                <a href="<%= request.getContextPath()%>/AppointmentServlet?action=history&status=all" class="section-btn btn btn-primary" style="margin: 10px;">
                                    <i class="fa fa-history"></i> View All Past Appointments
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>
        <%
            }
        %>

        <!-- ABOUT -->
        <section id="about">
            <div class="container">
                <div class="row">
                    <div class="col-md-6 col-sm-6">
                        <div class="about-info">
                            <h2 class="wow fadeInUp" data-wow-delay="0.6s">We care for your <i
                                    class="fa fa-h-square"></i>ealth</h2>
                            <div class="wow fadeInUp" data-wow-delay="0.8s">
                                <p>APU Medical Center (AMC) is your trusted healthcare partner, providing
                                    comprehensive medical services to meet all your health needs.
                                    Since our establishment, we have been committed to delivering quality healthcare
                                    with a patient-centered approach that puts your well-being first.</p>

                                <p>Our experienced medical team specializes in treating chronic diseases such as
                                    diabetes, hypertension, and asthma, while also providing immediate care for
                                    common illnesses including flu, fever, and cough.
                                    We understand the importance of preventive care and offer comprehensive health
                                    check-ups for local students, as well as specialized EMGS medical screenings for
                                    international students.</p>

                                <p>At AMC, we stay current with healthcare needs by providing COVID-19 screening
                                    services through both PCR and RTK-Ag tests.
                                    Our dental services cover everything from routine check-ups and cleanings to
                                    extractions, ensuring your oral health is maintained. We also perform minor
                                    surgeries, wound care, and provide essential vaccinations and immunizations to
                                    keep you protected.</p>

                                <p>Our motto, <strong>"Patient Centered Treatments for Everyone"</strong>, reflects
                                    our commitment to accessible, quality healthcare that respects your individual
                                    needs and circumstances.</p>
                            </div>
                            <figure class="profile wow fadeInUp" data-wow-delay="1s">
                                <img src="<%= request.getContextPath()%>/images/cust_homepage/doc-image.jpg" class="img-responsive" alt="">
                                <figcaption>
                                    <h3>Dr. Neil Jackson</h3>
                                    <p>General Principal</p>
                                </figcaption>
                            </figure>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- TEAM -->
        <section id="team" data-stellar-background-ratio="1">
            <div class="container">
                <div class="row">

                    <div class="col-md-12 col-sm-12">
                        <div class="section-title wow fadeInUp" data-wow-delay="0.1s">
                            <h2>Our Doctors</h2>
                        </div>
                    </div>

                    <%
                        if (doctorList != null && !doctorList.isEmpty()) {
                            final int MAX_DOCTORS_HOMEPAGE = 3;
                            int doctorCount = Math.min(doctorList.size(), MAX_DOCTORS_HOMEPAGE);
                            double delay = 0.4;

                            // Calculate responsive column classes based on number of doctors
                            String colClass = "";
                            String containerClass = "row";

                            if (doctorCount == 1) {
                                colClass = "col-md-4 col-md-offset-4 col-sm-6 col-sm-offset-3";
                            } else if (doctorCount == 2) {
                                colClass = "col-md-4 col-sm-6";
                                containerClass = "row text-center";
                            } else {
                                colClass = "col-md-4 col-sm-6";
                            }
                    %>

                    <div class="<%= containerClass%>">
                        <%
                            for (int i = 0; i < doctorCount; i++) {
                                Doctor doc = doctorList.get(i);

                                // Handle doctor name validation
                                String doctorName = doc.getName();
                                if (doctorName == null || doctorName.trim().isEmpty()) {
                                    doctorName = "Doctor Name N/A";
                                }

                                // Handle specialization validation
                                String specialization = doc.getSpecialization();
                                if (specialization == null || specialization.trim().isEmpty()) {
                                    specialization = "General Practice";
                                }

                                // Handle profile picture validation
                                String profilePic = doc.getProfilePic();
                                if (profilePic == null || profilePic.trim().isEmpty()) {
                                    profilePic = "default-doctor.png";
                                }

                                // Handle phone validation
                                String phone = doc.getPhone();
                                if (phone == null || phone.trim().isEmpty()) {
                                    phone = "Contact clinic for details";
                                }

                                // Handle email validation
                                String email = doc.getEmail();
                                boolean hasValidEmail = (email != null && !email.trim().isEmpty() && email.contains("@"));
                        %>
                        <div class="<%= colClass%>">
                            <div class="team-thumb wow fadeInUp" data-wow-delay="<%= delay%>s">

                                <img src="<%= request.getContextPath()%>/images/profile_pictures/<%= profilePic%>" class="img-responsive" alt="<%= doctorName%> Profile Picture">
                                <div class="team-info">
                                    <h3><%= doctorName%></h3>
                                    <p class="doctor-specialization"><%= specialization%></p>
                                    <div class="team-contact-info">
                                        <p><i class="fa fa-phone"></i> <%= phone%></p>
                                        <% if (hasValidEmail) {%>
                                        <p><i class="fa fa-envelope-o"></i> <a href="mailto:<%= email%>"><%= email%></a></p>
                                            <% } else { %>
                                        <p><i class="fa fa-envelope-o"></i> Email not available</p>
                                        <% } %>
                                        <% if (doc.getRating() != null && doc.getRating().doubleValue() > 0) {%>
                                        <p class="doctor-rating">
                                            <i class="fa fa-star"></i> 
                                            Rating: <%= String.format("%.1f", doc.getRating())%>/10.0
                                        </p>
                                        <% } %>
                                    </div>
                                    <ul class="social-icon">
                                        <li><a class="fa fa-facebook-square" href="#"></a></li>
                                            <% if (hasValidEmail) {%>
                                        <li><a href="mailto:<%= email%>" class="fa fa-envelope-o"></a></li>
                                            <% } %>
                                    </ul>
                                </div>
                            </div>
                        </div>
                        <%
                                delay += 0.2;
                            }
                        %>
                    </div>

                    <!-- View All Doctors Button -->
                    <div class="col-md-12 col-sm-12 text-center" style="margin-top:30px;">
                        <% if (doctorList.size() > MAX_DOCTORS_HOMEPAGE) {%>
                        <p class="text-muted">Showing <%= doctorCount%> of <%= doctorList.size()%> doctors</p>
                        <% }%>
                        <a href="<%= request.getContextPath()%>/DoctorServlet" class="section-btn btn btn-default">
                            View All Doctors
                        </a>
                    </div>

                    <%
                    } else {
                    %>
                    <div class="col-md-12 col-sm-12 text-center">
                        <div class="alert alert-info">
                            <i class="fa fa-info-circle"></i>
                            <strong>No doctors available at the moment.</strong>
                            <p>Please check back later or contact us for more information.</p>
                        </div>
                    </div>
                    <% } %>

                </div>
            </div>
        </section>

        <!-- TREATMENTS -->
        <section id="treatments" data-stellar-background-ratio="2.5">
            <div class="container">
                <div class="row">

                    <div class="col-md-12 col-sm-12">
                        <!-- SECTION TITLE -->
                        <div class="section-title wow fadeInUp" data-wow-delay="0.1s">
                            <h2>Treatments Available</h2>
                        </div>
                    </div>

                    <%
                        if (treatmentList != null && !treatmentList.isEmpty()) {
                            final int MAX_TREATMENTS_HOMEPAGE = 3;
                            int treatmentCount = Math.min(treatmentList.size(), MAX_TREATMENTS_HOMEPAGE);
                            double delay = 0.4;

                            // Calculate responsive column classes based on number of treatments
                            String colClass = "";
                            String containerClass = "row";

                            if (treatmentCount == 1) {
                                colClass = "col-md-4 col-md-offset-4 col-sm-6 col-sm-offset-3";
                            } else if (treatmentCount == 2) {
                                colClass = "col-md-4 col-sm-6";
                                containerClass = "row text-center";
                            } else {
                                colClass = "col-md-4 col-sm-6";
                            }
                    %>

                    <div class="<%= containerClass%>">
                        <%
                            for (int i = 0; i < treatmentCount; i++) {
                                Treatment treatment = treatmentList.get(i);
                                if (treatment == null) {
                                    continue;
                                }

                                // Extract treatment name (characters before "-")
                                String displayName = treatment.getName();
                                if (displayName == null) {
                                    displayName = "Unnamed Treatment";
                                } else if (displayName.contains("-")) {
                                    displayName = displayName.substring(0, displayName.indexOf("-")).trim();
                                }

                                // Handle null/empty descriptions
                                String shortDesc = treatment.getShortDescription();
                                if (shortDesc == null || shortDesc.trim().isEmpty()) {
                                    shortDesc = "Treatment details available upon consultation.";
                                } else if (shortDesc.length() > 120) {
                                    shortDesc = shortDesc.substring(0, 120) + "...";
                                }

                                // Handle image path
                                String imagePath = treatment.getTreatmentPic();
                                if (imagePath == null || imagePath.trim().isEmpty()) {
                                    imagePath = "default-treatment.jpg";
                                }
                        %>
                        <div class="<%= colClass%>">
                            <!-- TREATMENT THUMB -->
                            <a href="<%= request.getContextPath()%>/TreatmentServlet?action=viewDetail&id=<%= treatment.getId()%>">

                                <div class="treatments-thumb wow fadeInUp" data-wow-delay="<%= delay%>s" data-treatment-id="<%= treatment.getId()%>">
                                    <div class="treatment-image clickable-treatment">
                                        <img src="<%= request.getContextPath()%>/images/treatment/<%= imagePath%>" class="img-responsive custom-treat-image" alt="<%= displayName%>">
                                    </div>
                                    <div class="treatments-info two-line-text">
                                        <h3>
                                            <span class="treatment-name clickable-treatment">
                                                <%= treatment.getName() != null ? treatment.getName() : "No name available"%>
                                            </span>
                                        </h3>
                                        <p><%= treatment.getShortDescription() != null ? treatment.getShortDescription() : "No short description."%></p>
                                    </div>
                                </div>
                            </a>
                        </div>
                        <%
                                delay += 0.2;
                            }
                        %>
                    </div>

                    <!-- View All Treatments Button -->
                    <div class="col-md-12 col-sm-12 text-center" style="margin-top:30px;">
                        <% if (treatmentList.size() > MAX_TREATMENTS_HOMEPAGE) {%>
                        <p class="text-muted">Showing <%= treatmentCount%> of <%= treatmentList.size()%> treatments</p>
                        <% }%>

                        <a href="<%= request.getContextPath()%>/TreatmentServlet?action=viewAll" class="section-btn btn btn-default">
                            View All Treatments
                        </a>
                    </div>

                    <%
                    } else {
                    %>
                    <div class="col-md-12 col-sm-12 text-center">
                        <div class="alert alert-info">
                            <i class="fa fa-info-circle"></i>
                            <strong>No treatments available at the moment.</strong>
                            <p>Please check back later or contact us for more information.</p>
                        </div>
                    </div>
                    <% }%>

                </div>
            </div>
        </section>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>

        <!-- Appointment Reminder JavaScript -->
        <script>
            $(document).ready(function() {
                // Smooth scroll to reminders when clicking reminder notifications
                $('.reminder-notification').click(function() {
                    $('html, body').animate({
                        scrollTop: $('.reminder-section').offset().top - 80
                    }, 800);
                });
            });
        </script>

    </body>

</html>

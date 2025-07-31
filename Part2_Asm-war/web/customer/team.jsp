<%@page import="java.util.Date"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.sql.Time"%>
<%@page import="model.Schedule"%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="model.Doctor" %>
<%@page import="model.Customer"%>

<%
    // Check if user is logged in
    Customer loggedInCustomer = (Customer) session.getAttribute("customer");
    System.out.println("Team.jsp" + loggedInCustomer);

    if (loggedInCustomer == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    } else {
        System.out.println(loggedInCustomer.getName() + " logged in succesfully!");
    }

    // Retrieve the list of doctors and treatments from the request attributes
    List<Doctor> doctorList = (List<Doctor>) request.getAttribute("doctorList");
%>

<%!
    // Helper method to convert 24-hour time to 12-hour format
    public String formatTime(Time time) {
        if (time == null) {
            return "";
        }
        try {
            SimpleDateFormat inputFormat = new SimpleDateFormat("HH:mm:ss");
            SimpleDateFormat outputFormat = new SimpleDateFormat("h:mm a");
            Date date = inputFormat.parse(time.toString());
            return outputFormat.format(date).toLowerCase();
        } catch (Exception e) {
            return time.toString(); // fallback
        }
    }

    // Helper method to get working hours display
    public String getWorkingHoursDisplay(List<Schedule> schedules) {
        if (schedules == null || schedules.isEmpty()) {
            return "Schedule not available";
        }

        StringBuilder workingHours = new StringBuilder();
        for (int i = 0; i < schedules.size(); i++) {
            Schedule schedule = schedules.get(i);
            if (i > 0) {
                workingHours.append(", ");
            }
            workingHours.append(schedule.getDayOfWeek()).append(": ")
                    .append(formatTime(schedule.getStartTime()))
                    .append(" - ")
                    .append(formatTime(schedule.getEndTime()));
        }
        return workingHours.toString();
    }
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Our Medical Team - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
        <style>
            @media (min-width: 992px) {
                .col-md-4 {
                    width: 33.33333333%;
                    margin-bottom: 40px;
                }
            }
        </style>
    </head>

    <body id="top" data-spy="scroll" data-target=".navbar-collapse" data-offset="50">

        <%@ include file="/includes/preloader.jsp" %>
        <%@ include file="/includes/header.jsp" %>
        <%@ include file="/includes/navbar.jsp" %>

        <!-- TEAM SECTION -->
        <section id="team" data-stellar-background-ratio="1">
            <div class="container">
                <div class="row">
                    <div class="col-md-12 col-sm-12">
                        <div class="section-title wow fadeInUp text-center" data-wow-delay="0.1s">
                            <h2>Meet Our Medical Team</h2>
                            <% if (doctorList
                                        != null && !doctorList.isEmpty()) {%>
                            <p>Our team of <%= doctorList.size()%> experienced medical professionals</p>
                            <% } %>
                        </div>
                    </div>

                    <%
                        if (doctorList
                                != null && !doctorList.isEmpty()) {
                            double delay = 0.4;
                            int doctorCount = doctorList.size();

                            // Always use col-md-4 for consistent 3-column layout
                            String colClass = "col-md-4 col-sm-6";

                            // Process doctors in groups of 3 for proper row structure
                            for (int i = 0; i < doctorCount; i++) {
                                Doctor doc = doctorList.get(i);

                                // Start new row every 3 doctors
                                if (i % 3 == 0) {
                    %>
                    <div class="row">
                        <%
                            }
                            // Handle doctor name validation
                            String doctorName = doc.getName();
                            if (doctorName == null || doctorName.trim().isEmpty()) {
                                doctorName = "Doctor Name Not Available";
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
                                <img src="<%= request.getContextPath()%>/ImageServlet?folder=profile_pictures&file=<%= profilePic%>" class="img-responsive custom-image-" alt="<%= doctorName%> Profile Picture">
                                <div class="team-info">
                                    <h3><%= doctorName%></h3>
                                    <p class="doctor-specialization"><%= specialization%></p>
                                    <div class="team-contact-info">
                                        <p><i class="fa fa-phone"></i> <%= phone%></p>
                                        <% if (hasValidEmail) {%>
                                        <p><i class="fa fa-envelope-o"></i> <a href="mailto:<%= email%>"><%= email%></a></p>
                                            <% } else { %>
                                        <p><i class="fa fa-envelope-o"></i> Email not available</p>
                                        <% }%>
                                        <p class="doctor-rating">
                                            <i class="fa fa-star"></i> 
                                            Rating: <%= (doc.getRating() != null && doc.getRating().doubleValue() > 0)
                                                    ? String.format("%.1f/10.0", doc.getRating())
                                                    : "<span style='color: #757575;'>No ratings yet</span>"%>
                                        </p>
                                        <p><i class="fa fa-clock-o"></i>Working Hours:
                                            <% if (doc.getSchedules() != null && !doc.getSchedules().isEmpty()) {%>
                                            <br>
                                            <% for (Schedule schedule : doc.getSchedules()) {%>
                                            <%= schedule.getDayOfWeek()%>: 
                                            <%= formatTime(schedule.getStartTime())%> - 
                                            <%= formatTime(schedule.getEndTime())%><br>
                                            <% } %>
                                            <% } else { %>
                                            <span style="color: #757575;">Schedule not available</span>
                                            <% }%>
                                        </p>
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

                            // Close row every 3 doctors or at the end
                            if ((i + 1) % 3 == 0 || i == doctorCount - 1) {
                        %>
                    </div>
                    <%
                            }
                        }
                    } else {
                    %>
                    <div class="row">
                        <div class="col-md-12 col-sm-12 text-center">
                            <div class="alert alert-info">
                                <i class="fa fa-info-circle"></i>
                                <strong>No doctors available at the moment.</strong>
                                <p>Please check back later or contact us for more information.</p>
                            </div>
                        </div>
                    </div>
                    <% }%>

                </div>
            </div>
        </section>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>

    </body>

</html>
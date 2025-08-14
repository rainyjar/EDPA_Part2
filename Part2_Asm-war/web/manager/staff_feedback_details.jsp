<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="model.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.text.DecimalFormat" %>

<%
    // Get data from servlet attributes (following ManagerServlet pattern)
    String staffType = (String) request.getAttribute("staffType");
    Integer staffId = (Integer) request.getAttribute("staffId");
    String staffName = (String) request.getAttribute("staffName");
    Object staffObject = request.getAttribute("staffObject");
    List<Feedback> feedbackList = (List<Feedback>) request.getAttribute("feedbackList");

    if (staffType == null || staffId == null || staffName == null || feedbackList == null) {
        response.sendRedirect(request.getContextPath() + "/StaffRatingServlet");
        return;
    }

    // Get rating from staff object using getRating() method
    Double averageRating = 0.0;
    if (staffObject != null) {
        if ("doctor".equals(staffType) && staffObject instanceof Doctor) {
            Doctor doctor = (Doctor) staffObject;
            averageRating = doctor.getRating();
            System.out.println("DEBUG: Doctor rating from getRating(): " + averageRating);
        } else if ("staff".equals(staffType) && staffObject instanceof CounterStaff) {
            CounterStaff counterStaff = (CounterStaff) staffObject;
            averageRating = counterStaff.getRating();
            System.out.println("DEBUG: Counter Staff rating from getRating(): " + averageRating);
        }
    } else {
        System.out.println("DEBUG: staffObject is null!");
    }
    
    // Handle null rating - if getRating() returns null or 0, calculate manually as fallback
    if (averageRating == null || averageRating == 0.0) {
        System.out.println("DEBUG: Rating is null or 0, calculating manually...");
        double totalRating = 0.0;
        int ratingCount = 0;
        
        for (Feedback feedback : feedbackList) {
            if ("doctor".equals(staffType) && feedback.getToDoctor() != null 
                && feedback.getToDoctor().getId() == staffId && feedback.getDocRating() > 0) {
                totalRating += feedback.getDocRating();
                ratingCount++;
            } else if ("staff".equals(staffType) && feedback.getToStaff() != null 
                      && feedback.getToStaff().getId() == staffId && feedback.getStaffRating() > 0) {
                totalRating += feedback.getStaffRating();
                ratingCount++;
            }
        }
        
        averageRating = ratingCount > 0 ? totalRating / ratingCount : 0.0;
        System.out.println("DEBUG: Calculated rating: " + averageRating + " from " + ratingCount + " feedbacks");
    }

    // Filter feedbacks for this specific staff member (JSP handles filtering)
    List<Feedback> staffFeedbacks = new ArrayList<Feedback>();
    int feedbackCount = 0;

    for (Feedback feedback : feedbackList) {
        boolean isForThisStaff = false;
        
        if ("doctor".equals(staffType) && feedback.getToDoctor() != null 
            && feedback.getToDoctor().getId() == staffId) {
            // Include all feedbacks for this doctor, regardless of rating value
            isForThisStaff = true;
        } else if ("staff".equals(staffType) && feedback.getToStaff() != null 
                  && feedback.getToStaff().getId() == staffId) {
            // Include all feedbacks for this staff, regardless of rating value
            isForThisStaff = true;
        }
        
        if (isForThisStaff) {
            staffFeedbacks.add(feedback);
            feedbackCount++;
        }
    }

    SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMM yyyy");
    SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm");
    DecimalFormat df = new DecimalFormat("#.#");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <title>Feedback Details - <%= staffName %></title>
    <%@ include file="/includes/head.jsp" %>
    <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manager-homepage.css">
    <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manage-staff.css">
    <link rel="stylesheet" href="<%= request.getContextPath()%>/css/staff-feedback-details.css">
</head>

<body>
    <button class="btn-close" onclick="window.close()">
        <i class="fa fa-times"></i>
    </button>

    <div class="feedback-header">
        <h2  style="color: white;"><i class="fa fa-star" style="color: white;"></i> Feedback Details</h2>
        <h3><%= staffName %></h3>
        <p style="color: antiquewhite;"><%= "doctor".equals(staffType) ? "Doctor" : "Counter Staff" %></p>
    </div>

    <div class="container" style="max-width: 800px;">
        <!-- Feedback Summary -->
        <div class="feedback-summary">
            <h4><i class="fa fa-chart-bar"></i> Rating Summary</h4>
            
            <div class="rating-display">
                <div class="rating-stars">
                    <% 
                        int fullStars = (int) Math.floor(averageRating);
                        for (int i = 0; i < fullStars; i++) {
                            out.print("<i class='fa fa-star'></i>");
                        }
                        if (averageRating - fullStars >= 0.5) {
                            out.print("<i class='fa fa-star-half-o'></i>");
                        }
                        for (int i = fullStars + (averageRating - fullStars >= 0.5 ? 1 : 0); i < 10; i++) {
                            out.print("<i class='fa fa-star-o'></i>");
                        }
                    %>
                </div>
                <div class="rating-number"><%= df.format(averageRating) %>/10</div>
            </div>
            
            <div class="text-center">
                <strong><%= feedbackCount %></strong> total feedback<%= feedbackCount != 1 ? "s" : "" %> received
            </div>
        </div>

        <!-- Individual Feedbacks -->
        <h4><i class="fa fa-comments"></i> Individual Customer Feedback</h4>
        
        <% if (staffFeedbacks.isEmpty()) { %>
            <div class="no-feedback">
                <i class="fa fa-comment-o"></i><br>
                No feedback received yet.
            </div>
        <% } else { %>
            <% for (Feedback feedback : staffFeedbacks) { %>
                <div class="feedback-item">
                    <!-- Customer and Feedback Info Header -->
                    <div class="feedback-header-info">
                        <div class="header-row">
                            <div class="customer-info">
                                <i class="fa fa-user"></i> Customer: 
                                <%= feedback.getFromCustomer() != null ? feedback.getFromCustomer().getName() : "Anonymous Customer" %>
                            </div>
                            <div class="feedback-date">
                                <i class="fa fa-calendar-check-o"></i> Appointment ID: 
                                #<%= feedback.getAppointment() != null ? feedback.getAppointment().getId() : "N/A" %>
                            </div>
                        </div>
                        
                        <!-- Appointment Details Row -->
                        <% if (feedback.getAppointment() != null) { 
                            Appointment appointment = feedback.getAppointment();
                        %>
                            <div class="appointment-row">
                                <div class="info-badge">
                                    <i class="fa fa-calendar"></i>
                                    <span><strong>Date:</strong> 
                                        <%= appointment.getAppointmentDate() != null 
                                            ? dateFormat.format(appointment.getAppointmentDate()) : "N/A" %>
                                    </span>
                                </div>
                                <div class="info-badge">
                                    <i class="fa fa-clock-o"></i>
                                    <span><strong>Time:</strong> 
                                        <%= appointment.getAppointmentTime() != null 
                                            ? timeFormat.format(appointment.getAppointmentTime()) : "N/A" %>
                                    </span>
                                </div>
                                <div class="info-badge">
                                    <i class="fa fa-info-circle"></i>
                                    <span><strong>Status:</strong> 
                                        <span class="badge badge-<%= "Completed".equals(appointment.getStatus()) ? "success" : "info" %>">
                                            <%= appointment.getStatus() != null ? appointment.getStatus() : "N/A" %>
                                        </span>
                                    </span>
                                </div>
                                <% if (appointment.getTreatment() != null) { %>
                                    <div class="info-badge">
                                        <i class="fa fa-stethoscope"></i>
                                        <span><strong>Treatment:</strong> <%= appointment.getTreatment().getName() %></span>
                                    </div>
                                <% } %>
                            </div>
                        <% } %>
                    </div>
                    
                    <div class="feedback-rating">
                        <span><strong>Rating:</strong></span>
                        <div class="rating-stars">
                            <% 
                                double rating = "doctor".equals(staffType) ? feedback.getDocRating() : feedback.getStaffRating();
                                if (rating > 0) {
                                    int stars = (int) Math.floor(rating);
                                    for (int i = 0; i < stars; i++) {
                                        out.print("<i class='fa fa-star'></i>");
                                    }
                                    if (rating - stars >= 0.5) {
                                        out.print("<i class='fa fa-star-half-o'></i>");
                                    }
                                    for (int i = stars + (rating - stars >= 0.5 ? 1 : 0); i < 10; i++) {
                                        out.print("<i class='fa fa-star-o'></i>");
                                    }
                                } else {
                                    // Show empty stars for 0 rating
                                    for (int i = 0; i < 10; i++) {
                                        out.print("<i class='fa fa-star-o'></i>");
                                    }
                                }
                            %>
                        </div>
                        <span><%= rating > 0 ? df.format(rating) + "/10" : "No Rating Given" %></span>
                    </div>
                    
                    <% 
                        String comment = "doctor".equals(staffType) ? feedback.getCustDocComment() : feedback.getCustStaffComment();
                        if (comment != null && !comment.trim().isEmpty()) {
                    %>
                        <div class="feedback-comment">
                            <i class="fa fa-quote-left"></i> 
                            <%= comment %>
                        </div>
                        <% if (feedback.getFromCustomer() != null) { %>
                            <div style="text-align: right; margin-top: 10px; font-size: 12px; color: #666;">
                                <em>- <%= feedback.getFromCustomer().getName() %></em>
                            </div>
                        <% } %>
                    <% } else { %>
                        <div class="feedback-comment" style="color: #999;">
                            <em>No comment provided</em>
                        </div>
                        <% if (feedback.getFromCustomer() != null) { %>
                            <div style="text-align: right; margin-top: 10px; font-size: 12px; color: #666;">
                                <em>- <%= feedback.getFromCustomer().getName() %></em>
                            </div>
                        <% } %>
                    <% } %>
                </div>
            <% } %>
        <% } %>
    </div>

    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script>
        // Close window with Escape key
        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape') {
                window.close();
            }
        });
        
        // Print functionality
        function printFeedback() {
            window.print();
        }
    </script>
</body>
</html>

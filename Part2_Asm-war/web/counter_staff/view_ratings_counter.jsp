<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="model.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.text.DecimalFormat" %>

<%
    // Check if counter staff is logged in
    CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");
    if (loggedInStaff == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // DEBUG: Print logged in staff info
    System.out.println("=== DEBUGGING COUNTER STAFF RATINGS ===");
    System.out.println("Logged in staff: " + loggedInStaff.getName() + " (ID: " + loggedInStaff.getId() + ")");

    // Get feedback data from servlet attributes
    List<Feedback> allFeedbacks = (List<Feedback>) request.getAttribute("feedbackList");
    Double averageRating = (Double) request.getAttribute("averageRating");

    // DEBUG: Print servlet attributes
    System.out.println("feedbackList from servlet: " + (allFeedbacks != null ? allFeedbacks.size() + " items" : "NULL"));
    System.out.println("averageRating from servlet: " + averageRating);

    // If data not available, initialize empty lists
    if (allFeedbacks == null) {
        allFeedbacks = new ArrayList<Feedback>();
        System.out.println("WARNING: No feedback data from servlet, initializing empty list");
    }

    // DEBUG: Print all feedbacks to see what we have
    System.out.println("Total feedbacks in list: " + allFeedbacks.size());
    for (int i = 0; i < allFeedbacks.size(); i++) {
        Feedback fb = allFeedbacks.get(i);
        System.out.println("Feedback " + i + ": ID=" + fb.getId()
                + ", toStaff=" + (fb.getToStaff() != null ? fb.getToStaff().getId() + "(" + fb.getToStaff().getName() + ")" : "NULL")
                + ", fromCustomer=" + (fb.getFromCustomer() != null ? fb.getFromCustomer().getName() : "NULL")
                + ", staffRating=" + fb.getStaffRating()
                + ", comment=" + (fb.getCustStaffComment() != null ? "'" + fb.getCustStaffComment() + "'" : "NULL"));
    }

    // Filter feedbacks for the logged-in counter staff
    List<Feedback> myFeedbacks = new ArrayList<Feedback>();
    double totalRating = 0.0;
    int ratingCount = 0;

    System.out.println("Filtering feedbacks for staff ID: " + loggedInStaff.getId());
    for (Feedback feedback : allFeedbacks) {
        if (feedback.getToStaff() != null && feedback.getToStaff().getId() == loggedInStaff.getId()) {
            myFeedbacks.add(feedback);
            System.out.println("MATCH: Found feedback for this staff - Rating: " + feedback.getStaffRating());
            if (feedback.getStaffRating() > 0) {
                totalRating += feedback.getStaffRating();
                ratingCount++;
                System.out.println("Added to total - Current total: " + totalRating + ", count: " + ratingCount);
            }
        }
    }

    System.out.println("Filtered results: " + myFeedbacks.size() + " feedbacks for this staff");
    System.out.println("Total rating: " + totalRating + ", Rating count: " + ratingCount);

    // Calculate average rating if not provided
    if (averageRating == null || averageRating == 0.0) {
        averageRating = ratingCount > 0 ? totalRating / ratingCount : 0.0;
        System.out.println("Calculated average rating: " + averageRating);
    } else {
        System.out.println("Using servlet-provided average rating: " + averageRating);
    }

    // Rating distribution
    int[] ratingDistribution = new int[11]; // 0-10 ratings
    System.out.println("Calculating rating distribution...");
    for (Feedback feedback : myFeedbacks) {
        if (feedback.getStaffRating() > 0) {
            int rating = (int) Math.round(feedback.getStaffRating());
            System.out.println("Processing feedback rating: " + feedback.getStaffRating() + " -> rounded to: " + rating);
            if (rating >= 0 && rating <= 10) {
                ratingDistribution[rating]++;
                System.out.println("Added to distribution[" + rating + "], now count: " + ratingDistribution[rating]);
            }
        }
    }

    // DEBUG: Print rating distribution
    System.out.println("Final rating distribution:");
    for (int i = 0; i <= 10; i++) {
        if (ratingDistribution[i] > 0) {
            System.out.println("Rating " + i + ": " + ratingDistribution[i] + " count(s)");
        }
    }

    SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMM yyyy");
    SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm");
    DecimalFormat df = new DecimalFormat("#.#");

    // Get recent feedbacks (last 5)
    List<Feedback> recentFeedbacks = new ArrayList<Feedback>();
    int count = 0;
    System.out.println("Getting recent feedbacks (last 5 from " + myFeedbacks.size() + " total)...");
    for (int i = myFeedbacks.size() - 1; i >= 0 && count < 5; i--) {
        recentFeedbacks.add(myFeedbacks.get(i));
        System.out.println("Added recent feedback " + count + ": " + myFeedbacks.get(i).getId());
        count++;
    }
    System.out.println("Recent feedbacks list size: " + recentFeedbacks.size());
    System.out.println("=== END DEBUGGING ===");
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>My Ratings & Feedback - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manager-homepage.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manage-staff.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/staff-feedback-details.css">
        <style>
            .rating-dashboard {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 40px 20px;
                border-radius: 15px;
                margin-bottom: 30px;
                text-align: center;
            }

            .rating-overview {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                gap: 20px;
                margin-bottom: 30px;
            }

            .stat-card {
                background: white;
                padding: 25px;
                border-radius: 10px;
                box-shadow: 0 4px 15px rgba(0,0,0,0.1);
                text-align: center;
                transition: transform 0.3s ease;
            }

            .stat-card:hover {
                transform: translateY(-5px);
            }

            .stat-number {
                font-size: 2.5em;
                font-weight: bold;
                color: #667eea;
                margin-bottom: 10px;
            }

            .stat-label {
                color: #666;
                font-size: 0.9em;
                text-transform: uppercase;
                letter-spacing: 1px;
            }

            .rating-distribution {
                background: white;
                padding: 25px;
                border-radius: 10px;
                box-shadow: 0 4px 15px rgba(0,0,0,0.1);
                margin-bottom: 30px;
            }

            .distribution-bar {
                display: flex;
                align-items: center;
                margin-bottom: 10px;
            }

            .rating-label {
                width: 60px;
                font-weight: bold;
            }

            .rating-count {
                width: 40px;
                text-align: right;
                font-weight: bold;
                color: #667eea;
            }

            .feedback-timeline {
                background: white;
                border-radius: 10px;
                box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            }

            .timeline-header {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 20px 25px;
                border-radius: 10px 10px 0 0;
            }

            .feedback-item {
                border-bottom: 1px solid #eee;
                padding: 25px;
            }

            .feedback-item:last-child {
                border-bottom: none;
            }

            .customer-header {
                display: flex;
                justify-content: space-between;
                align-items: center;
                margin-bottom: 15px;
            }

            .customer-info {
                display: flex;
                align-items: center;
                gap: 10px;
            }

            .customer-avatar {
                width: 40px;
                height: 40px;
                border-radius: 50%;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                display: flex;
                align-items: center;
                justify-content: center;
                color: white;
                font-weight: bold;
            }

            .appointment-badges {
                display: flex;
                gap: 10px;
                margin-bottom: 15px;
                flex-wrap: wrap;
            }

            .badge {
                padding: 5px 12px;
                border-radius: 20px;
                font-size: 0.8em;
                font-weight: 500;
            }

            .badge-primary { background: #e3f2fd; color: #1976d2; }
            .badge-success { background: #e8f5e8; color: #2e7d32; }
            .badge-info { background: #f3e5f5; color: #7b1fa2; }

            .no-feedback-state {
                text-align: center;
                padding: 60px 20px;
                color: #999;
            }

            .no-feedback-state i {
                font-size: 4em;
                margin-bottom: 20px;
                opacity: 0.3;
            }

            .page-header-custom {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 60px 0;
                margin-bottom: 40px;
            }

            .breadcrumb-custom {
                background: transparent;
                margin: 0;
            }

            .breadcrumb-custom .breadcrumb-item a {
                color: rgba(255,255,255,0.8);
            }

            .breadcrumb-custom .breadcrumb-item.active {
                color: white;
            }

            .section-title {
                display: flex;
                align-items: center;
                gap: 10px;
                margin-bottom: 20px;
                font-size: 1.3em;
                font-weight: 600;
                color: #333;
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
                            <i class="fa fa-star" style="color:white"></i>
                            <span style="color:white">My Ratings</span>
                        </h1>
                        <p class="lead wow fadeInUp" data-wow-delay="0.2s" style="color: whitesmoke">
                            View customer feedback and ratings for your service
                        </p>
                        <nav aria-label="breadcrumb" class="wow fadeInUp" data-wow-delay="0.3s">
                            <ol class="breadcrumb"  style="background: transparent; margin: 0;"> 
                                <li class="breadcrumb-item"><a href="<%= request.getContextPath()%>/CounterStaffServletJam?action=dashboard" style="color: rgba(255,255,255,0.8)">Dashboard</a>
                                </li>
                                <li class="breadcrumb-item active" style="color: white;">My Ratings & Feedback</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>
        </section>

        <!-- MAIN CONTENT -->
        <section style="padding: 40px 0; background: #f5f5f5;">
            <div class="container">
                <!-- Rating Dashboard -->
                <div class="rating-dashboard wow fadeInUp" data-wow-delay="0.2s">
                    <h2 style="margin-bottom: 30px;">
                        <i class="fa fa-user" style="color:white"></i>
                        <span style="color:white"><%= loggedInStaff.getName()%></span>
                    </h2>

                    <div style="display: flex; justify-content: center; align-items: center; gap: 30px; flex-wrap: wrap;">
                        <div>
                            <div class="rating-stars" style="font-size: 2em; margin-bottom: 10px;">
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
                            <div style="font-size: 2.5em; font-weight: bold; margin-bottom: 10px;">
                                <%= df.format(averageRating)%>/10
                            </div>
                            <div style="opacity: 0.9;">Overall Rating</div>
                        </div>
                    </div>
                </div>

                <!-- Rating Overview -->
                <div class="rating-overview wow fadeInUp" data-wow-delay="0.2s">
                    <div class="stat-card">
                        <div class="stat-number"><%= myFeedbacks.size()%></div>
                        <div class="stat-label">Total Feedback</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-number"><%= ratingCount%></div>
                        <div class="stat-label">Rated Appointments</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-number">
                            <%= ratingCount > 0 ? Math.round((double) ratingCount / myFeedbacks.size() * 100) : 0%>%
                        </div>
                        <div class="stat-label">Response Rate</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-number">
                            <%
                                int excellentRatings = 0;
                                for (int i = 8; i <= 10; i++) {
                                    excellentRatings += ratingDistribution[i];
                                }
                            %>
                            <%= excellentRatings%>
                        </div>
                        <div class="stat-label">Excellent Ratings (8-10)</div>
                    </div>
                </div>

                <!-- Recent Feedback -->
                <div class="feedback-timeline wow fadeInUp" data-wow-delay="0.4s">
                    <div class="timeline-header">
                        <h3 style="margin: 0;">
                            <i class="fa fa-comments"></i>
                            Recent Customer Feedback
                            <span style="float: right; font-size: 0.9em; opacity: 0.8;">
                                <%= recentFeedbacks.size()%> of <%= myFeedbacks.size()%> shown
                            </span>
                        </h3>
                    </div>

                    <% if (myFeedbacks.isEmpty()) { %>
                    <div class="no-feedback-state">
                        <i class="fa fa-comment-o"></i>
                        <h4>No Feedback Yet</h4>
                        <p>You haven't received any customer feedback yet.<br>
                            Keep providing excellent service and feedback will start coming in!</p>
                    </div>
                    <% } else { %>
                    <% for (Feedback feedback : recentFeedbacks) {%>
                    <div class="feedback-item">
                        <div class="customer-header">
                            <div class="customer-info">
                                <div class="customer-avatar">
                                    <%= feedback.getFromCustomer() != null
                                            ? feedback.getFromCustomer().getName().substring(0, 1).toUpperCase()
                                            : "?"%>
                                </div>
                                <div>
                                    <div style="font-weight: 600; font-size: 1.1em;">
                                        <%= feedback.getFromCustomer() != null
                                                ? feedback.getFromCustomer().getName()
                                                : "Anonymous Customer"%>
                                    </div>
                                    <div style="color: #666; font-size: 0.9em;">
                                        <i class="fa fa-clock-o"></i>
                                        <%= feedback.getAppointment() != null && feedback.getAppointment().getAppointmentDate() != null
                                                ? dateFormat.format(feedback.getAppointment().getAppointmentDate())
                                                : "Date N/A"%>
                                    </div>
                                </div>
                            </div>
                            <div class="feedback-rating" style="text-align: right;">
                                <div class="rating-stars" style="margin-bottom: 5px;">
                                    <%
                                        double rating = feedback.getStaffRating();
                                        if (rating > 0) {
                                            int stars = (int) Math.floor(rating);
                                            for (int i = 0; i < stars; i++) {
                                                out.print("<i class='fa fa-star' style='color: #ffc107;'></i>");
                                            }
                                            if (rating - stars >= 0.5) {
                                                out.print("<i class='fa fa-star-half-o' style='color: #ffc107;'></i>");
                                            }
                                            for (int i = stars + (rating - stars >= 0.5 ? 1 : 0); i < 10; i++) {
                                                out.print("<i class='fa fa-star-o' style='color: #ddd;'></i>");
                                            }
                                        } else {
                                            for (int i = 0; i < 10; i++) {
                                                out.print("<i class='fa fa-star-o' style='color: #ddd;'></i>");
                                            }
                                        }
                                    %>
                                </div>
                                <div style="font-weight: bold; color: #667eea;">
                                    <%= rating > 0 ? df.format(rating) + "/10" : "No Rating"%>
                                </div>
                            </div>
                        </div>

                        <% if (feedback.getAppointment() != null) {%>
                        <div class="appointment-badges">
                            <span class="badge badge-primary">
                                <i class="fa fa-hashtag"></i> Appointment #<%= feedback.getAppointment().getId()%>
                            </span>
                            <% if (feedback.getAppointment().getTreatment() != null) {%>
                            <span class="badge badge-info">
                                <i class="fa fa-stethoscope"></i> <%= feedback.getAppointment().getTreatment().getName()%>
                            </span>
                            <% }%>
                            <span class="badge badge-success">
                                <i class="fa fa-check"></i>
                                <%= feedback.getAppointment().getStatus().substring(0, 1).toUpperCase() + feedback.getAppointment().getStatus().substring(1).toLowerCase()%>
                            </span>
                        </div>
                        <% } %>

                        <%
                            String comment = feedback.getCustStaffComment();
                            if (comment != null && !comment.trim().isEmpty()) {
                        %>
                        <div class="feedback-comment" style="background: #f8f9fa; padding: 15px; border-radius: 8px; border-left: 4px solid #667eea;">
                            <i class="fa fa-quote-left" style="color: #667eea; opacity: 0.7;"></i>
                            <span style="font-style: italic; color: #333; margin-left: 10px;"><%= comment%></span>
                        </div>
                        <% } else { %>
                        <div style="color: #999; font-style: italic; padding: 10px; background: #f8f9fa; border-radius: 8px;">
                            <i class="fa fa-comment-o"></i> No written feedback provided
                        </div>
                        <% } %>
                    </div>
                    <% } %>

                    <% if (myFeedbacks.size() > 5) {%>
                    <div style="text-align: center; padding: 20px; background: #f8f9fa;">
                        <button class="btn btn-outline-primary" onclick="showAllFeedback()">
                            <i class="fa fa-plus"></i> View All <%= myFeedbacks.size()%> Feedback
                        </button>
                    </div>
                    <% } %>
                    <% }%>
                </div>
            </div>
        </section>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>

        <script>
            function showAllFeedback() {
                // This could redirect to a full feedback page or load more via AJAX
                window.location.href = '<%= request.getContextPath()%>/FeedbackServlet?action=viewAllMyFeedback';
            }

            // Auto-refresh every 5 minutes to get latest feedback
            setTimeout(function () {
                location.reload();
            }, 300000);
        </script>
    </body>
</html>

<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="model.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.text.DecimalFormat" %>

<%
    // Check if doctor is logged in
    Doctor loggedInDoctor = (Doctor) session.getAttribute("doctor");
    if (loggedInDoctor == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    // Get feedback data from servlet attributes
    List<Feedback> allFeedbacks = (List<Feedback>) request.getAttribute("feedbackList");
    Double averageRating = (Double) request.getAttribute("averageRating");

    // If data not available, initialize empty lists
    if (allFeedbacks == null) {
        allFeedbacks = new ArrayList<Feedback>();
    }

    // Set default average rating if not provided
    if (averageRating == null) {
        averageRating = 0.0;
    }

    // Calculate statistics
    double totalRating = 0.0;
    int ratingCount = 0;

    for (Feedback feedback : allFeedbacks) {
        if (feedback.getDocRating() > 0) {
            totalRating += feedback.getDocRating();
            ratingCount++;
        }
    }

    // Rating distribution
    int[] ratingDistribution = new int[11]; // 0-10 ratings
    for (Feedback feedback : allFeedbacks) {
        if (feedback.getDocRating() > 0) {
            int rating = (int) Math.round(feedback.getDocRating());
            if (rating >= 0 && rating <= 10) {
                ratingDistribution[rating]++;
            }
        }
    }

    SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMM yyyy");
    SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm");
    DecimalFormat df = new DecimalFormat("#.#");

    // Get recent feedbacks (last 5)
    List<Feedback> recentFeedbacks = new ArrayList<Feedback>();
    int count = 0;
    for (int feedbackIdx = allFeedbacks.size() - 1; feedbackIdx >= 0 && count < 5; feedbackIdx--) {
        recentFeedbacks.add(allFeedbacks.get(feedbackIdx));
        count++;
    }
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>My Ratings & Feedback - AMC Healthcare System</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manager-homepage.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manage-staff.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/doctor-ratings.css">
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
                            View patient feedback and ratings for your medical service
                        </p>
                        <nav aria-label="breadcrumb" class="wow fadeInUp" data-wow-delay="0.3s">
                            <ol class="breadcrumb" style="background: transparent; margin: 0;">
                                <li class="breadcrumb-item">
                                    <a href="<%= request.getContextPath()%>/DoctorHomepageServlet" style="color: rgba(255,255,255,0.8);">Dashboard</a>
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
                        <i class="fa fa-user-md" style="color:white"></i>
                        <span style="color:white">Dr. <%= loggedInDoctor.getName()%></span>
                    </h2>

                    <div style="display: flex; justify-content: center; align-items: center; gap: 30px; flex-wrap: wrap;">
                        <div>
                            <div class="rating-stars" style="font-size: 2em; margin-bottom: 10px;">
                                <%
                                    // Display stars based on rating (out of 10, convert to 5 star display)
                                    int starRating = (int) Math.round(averageRating / 2);
                                    for (int starIdx = 1; starIdx <= 5; starIdx++) {
                                        if (starIdx <= starRating) {
                                %>
                                <i class="fa fa-star" style="color: #ffd700;"></i>
                                <%
                                        } else {
                                %>
                                <i class="fa fa-star-o" style="color: #ffd700;"></i>
                                <%
                                        }
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
                        <div class="stat-number"><%= allFeedbacks.size()%></div>
                        <div class="stat-label">Total Feedback</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-number"><%= ratingCount%></div>
                        <div class="stat-label">Rated Consultations</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-number">
                            <%= ratingCount > 0 ? Math.round((double) ratingCount / allFeedbacks.size() * 100) : 0%>%
                        </div>
                        <div class="stat-label">Response Rate</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-number">
                            <%
                                int excellentRatings = 0;
                                for (int ratingIdx = 8; ratingIdx <= 10; ratingIdx++) {
                                    excellentRatings += ratingDistribution[ratingIdx];
                                }
                            %>
                            <%= excellentRatings%>
                        </div>
                        <div class="stat-label">Excellent Ratings (8-10)</div>
                    </div>
                </div>

                <!-- Rating Distribution -->
                <% if (ratingCount > 0) { %>
                <div class="rating-distribution wow fadeInUp" data-wow-delay="0.3s">
                    <div class="section-title">
                        <i class="fa fa-bar-chart"></i>
                        <span>Rating Distribution</span>
                    </div>
                    
                    <%
                        int maxCount = 1;
                        for (int ratingValue : ratingDistribution) {
                            if (ratingValue > maxCount) maxCount = ratingValue;
                        }
                        
                        // Show ratings 10 to 1
                        for (int ratingLevel = 10; ratingLevel >= 1; ratingLevel--) {
                            if (ratingDistribution[ratingLevel] > 0) {
                                double percentage = (double) ratingDistribution[ratingLevel] / maxCount * 100;
                    %>
                    <div class="distribution-bar">
                        <div class="rating-label"><%= ratingLevel %> ⭐</div>
                        <div class="rating-bar">
                            <div class="rating-fill" style="width: <%= percentage %>%;"></div>
                        </div>
                        <div class="rating-count"><%= ratingDistribution[ratingLevel] %></div>
                    </div>
                    <%
                            }
                        }
                    %>
                </div>
                <% } %>

                <!-- Recent Feedback -->
                <div class="feedback-timeline wow fadeInUp" data-wow-delay="0.4s">
                    <div class="timeline-header">
                        <h3 style="margin: 0;">
                            <i class="fa fa-comments"></i>
                            Recent Patient Feedback
                            <span style="float: right; font-size: 0.9em; opacity: 0.8;">
                                <%= recentFeedbacks.size()%> of <%= allFeedbacks.size()%> shown
                            </span>
                        </h3>
                    </div>

                    <% if (allFeedbacks.isEmpty()) { %>
                    <div class="no-feedback-state">
                        <i class="fa fa-comment-o"></i>
                        <h4>No Feedback Yet</h4>
                        <p>You haven't received any patient feedback yet.<br>
                            Keep providing excellent medical care and feedback will start coming in!</p>
                    </div>
                    <% } else { %>
                    <% for (Feedback feedback : recentFeedbacks) {%>
                    <div class="feedback-item">
                        <div class="customer-header">
                            <div class="customer-info">
                                <div class="customer-avatar">
                                    <%= feedback.getFromCustomer() != null ? 
                                        feedback.getFromCustomer().getName().substring(0, 1).toUpperCase() : "?" %>
                                </div>
                                <div>
                                    <strong><%= feedback.getFromCustomer() != null ? 
                                        feedback.getFromCustomer().getName() : "Anonymous"%></strong>
                                    <div style="font-size: 0.9em; color: #666;">
                                        <%= feedback.getAppointment() != null && feedback.getAppointment().getAppointmentDate() != null ? 
                                            dateFormat.format(feedback.getAppointment().getAppointmentDate()) : "Date N/A" %>
                                    </div>
                                </div>
                            </div>
                            <div class="feedback-rating" style="text-align: right;">
                                <div class="rating-stars" style="margin-bottom: 5px;">
                                    <%
                                        // Display stars for this feedback (convert 10-point to 5-star)
                                        int feedbackStars = (int) Math.round(feedback.getDocRating() / 2);
                                        for (int feedbackStarIdx = 1; feedbackStarIdx <= 5; feedbackStarIdx++) {
                                            if (feedbackStarIdx <= feedbackStars) {
                                    %>
                                    <i class="fa fa-star"></i>
                                    <%
                                            } else {
                                    %>
                                    <i class="fa fa-star-o"></i>
                                    <%
                                            }
                                        }
                                    %>
                                </div>
                                <div style="font-size: 0.9em; color: #666;">
                                    <%= df.format(feedback.getDocRating())%>/10
                                </div>
                            </div>
                        </div>

                        <% if (feedback.getAppointment() != null) {%>
                        <div class="appointment-badges">
                            <span class="badge badge-primary">
                                <i class="fa fa-calendar"></i> 
                                Appointment #<%= feedback.getAppointment().getId()%>
                            </span>
                            <% if (feedback.getAppointment().getTreatment() != null) {%>
                            <span class="badge badge-info">
                                <i class="fa fa-stethoscope"></i> 
                                <%= feedback.getAppointment().getTreatment().getName()%>
                            </span>
                            <% }%>
                            <span class="badge badge-success">
                                <i class="fa fa-check"></i> Completed
                            </span>
                        </div>
                        <% } %>

                        <%
                            String comment = feedback.getCustDocComment();
                            if (comment != null && !comment.trim().isEmpty()) {
                        %>
                        <div class="feedback-comment" style="background: #f8f9fa; padding: 15px; border-radius: 8px; border-left: 4px solid #007bff;">
                            <i class="fa fa-quote-left" style="color: #007bff; opacity: 0.7;"></i>
                            <span style="font-style: italic; color: #333; margin-left: 10px;"><%= comment%></span>
                        </div>
                        <% } else { %>
                        <div style="color: #999; font-style: italic; padding: 10px; background: #f8f9fa; border-radius: 8px;">
                            <i class="fa fa-comment-o"></i> No written feedback provided
                        </div>
                        <% } %>
                    </div>
                    <% } %>

                    <% if (allFeedbacks.size() > 5) {%>
                    <div style="text-align: center; padding: 20px; background: #f8f9fa;">
                        <button class="btn btn-outline-primary" onclick="showAllFeedback()">
                            <i class="fa fa-plus"></i> View All <%= allFeedbacks.size()%> Feedback
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
                alert('Full feedback page can be implemented here');
            }

            // Auto-refresh every 10 minutes to get latest feedback
            setTimeout(function () {
                location.reload();
            }, 600000);

            // Animate rating bars on page load
            $(document).ready(function() {
                $('.rating-fill').each(function() {
                    var width = $(this).css('width');
                    $(this).css('width', '0%').animate({'width': width}, 1000);
                });
            });
        </script>
    </body>
</html>

<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="model.Treatment" %>
<%@ page import="model.CounterStaff" %>

<%
    // Check if counter staff is logged in
    CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");
    System.out.println("Counter Staff Treatments.jsp - Staff: " + loggedInStaff);

    if (loggedInStaff == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    } else {
        System.out.println("Counter Staff " + loggedInStaff.getName() + " accessing treatments page!");
    }

    // Check if we need to load treatment data
    List<Treatment> treatmentList = (List<Treatment>) request.getAttribute("treatmentList");
    if (treatmentList == null) {
        // Redirect to servlet to load treatment data
        response.sendRedirect(request.getContextPath() + "/TreatmentServlet?action=viewAll&role=staff");
        return;
    }
%>

<!DOCTYPE html>
<html lang="en">

    <head>
        <title>View Treatments - Counter Staff - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/staff.css">
        <style>
            .custom-treat-image {
                aspect-ratio: 16/9;
                object-fit: cover;         
            }
            .treatments-thumb {
                max-height: 450px;         
                min-height: 400px;  
                overflow: hidden;           /* Prevents overflow */
                border: 1px solid #ddd;
                border-radius: 10px;
                background-color: #fff;
                box-shadow: 0 2px 6px rgba(0,0,0,0.1);
                transition: transform 0.3s ease, box-shadow 0.3s ease;
            }

            .treatments-thumb:hover {
                transform: translateY(-5px);
                box-shadow: 0 8px 25px rgba(0,0,0,0.15);
            }

            .treatments-info p, .treatments-name p {
                max-height: 60px;           /* Limit text height */
                overflow: hidden;
                text-overflow: ellipsis;
                white-space: nowrap;
                line-height: 1.3em;
                display: -webkit-box;
                -webkit-line-clamp: 3;      /* Show 3 lines max */
                -webkit-box-orient: vertical;
            }

            .two-line-text h3{
                display: -webkit-box; /* Required for -webkit-line-clamp */
                -webkit-box-orient: vertical; /* Required for -webkit-line-clamp */
                -webkit-line-clamp: 2; /* Limits the text to 2 lines */
                overflow: hidden; /* Hides any overflowing content */
                text-overflow: ellipsis; /* Adds an ellipsis (...) to truncated text */
                white-space: normal; /* Allows text to wrap within the two lines */
            }

            .staff-badge {
                background: linear-gradient(135deg, #2c2577 0%, #f41212 100%);
                color: white;
                padding: 5px 15px;
                border-radius: 15px;
                font-size: 0.8em;
                margin-bottom: 10px;
                display: inline-block;
            }

            .counter-staff-header {
                background: linear-gradient(135deg, #2c2577 0%, #f41212 100%);
            }

            @media (max-width: 768px) {
                .treatments-thumb {
                    max-height: none;
                    min-height: auto;
                }
            }

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

        <!-- TREATMENTS SECTION -->
        <section id="treatments" class="counter-staff-header" data-stellar-background-ratio="2.5" style="padding: 60px 0px;background-position: 0px 172.482px;background: linear-gradient(135deg, #2c2577 0%, #f41212 100%);">
            <div class="container">
                <div class="row">
                    <div class="col-md-12 col-sm-12">
                        <!-- SECTION TITLE -->
                        <div class="section-title wow fadeInUp" data-wow-delay="0.1s">
                            <span class="staff-badge">
                                <i class="fa fa-user-md"></i> Counter Staff Access
                            </span>
                            <h2 style="color: white;">All Available Treatments</h2>
                            <% if (treatmentList != null && !treatmentList.isEmpty()) {%>
                            <p style="color: rgba(255,255,255,0.9);">Browse <%= treatmentList.size()%> specialized treatment services to assist customers</p>
                            <% } %>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <section style="background: #f8f9fa; padding: 40px 0;">
            <div class="container">
                <%
                    if (treatmentList != null && !treatmentList.isEmpty()) {
                        double delay = 0.4;
                        int treatmentCount = treatmentList.size();

                        // Always use col-md-4 for consistent 3-column layout
                        String colClass = "col-md-4 col-sm-6";

                        // Process treatments in groups of 3 for proper row structure
                        for (int i = 0; i < treatmentCount; i++) {
                            Treatment treatment = treatmentList.get(i);

                            // Start new row every 3 treatments
                            if (i % 3 == 0) {
                %>
                <div class="row">
                    <%
                        }
                        // Extract treatment name (characters before "-")
                        String displayName = treatment.getName();
                        if (displayName != null && displayName.contains("-")) {
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
                        String treatmentImagePath = treatment.getTreatmentPic();
                        String treatmentPic = (treatmentImagePath != null && !treatmentImagePath.isEmpty())
                                ? (request.getContextPath() + "/ImageServlet?folder=treatment&file=" + treatmentImagePath)
                                : (request.getContextPath() + "/images/placeholder/default-treatment.jpg");
                    %>
                    <div class="<%= colClass%>">
                        <!-- TREATMENT THUMB -->
                        <a href="<%= request.getContextPath()%>/TreatmentServlet?action=viewDetail&id=<%= treatment.getId()%>&role=staff">

                            <div class="treatments-thumb wow fadeInUp" data-wow-delay="<%= delay%>s" data-treatment-id="<%= treatment.getId()%>">
                                <div class="treatment-image clickable-treatment">
                                    <img src="<%= treatmentPic%>" class="img-responsive custom-treat-image" alt="<%= treatmentPic%>">
                                </div>
                                <div class="treatments-info treatments-name two-line-text">
                                    <h3>
                                        <%= treatment.getName() != null ? treatment.getName() : "No name available"%>
                                    </h3>
                                    <p><%= treatment.getShortDescription() != null ? treatment.getShortDescription() : "No short description."%></p>
                                    <div class="treatment-meta">
                                        <% if (treatment.getBaseConsultationCharge() > 0) {%>
                                        <p class="treatment-price">
                                            <i class="fa fa-money"></i> 
                                            Base Consultation: RM <%= String.format("%.2f", treatment.getBaseConsultationCharge())%>
                                        </p>
                                        <% } %>
                                    </div>
                                </div>
                            </div>
                        </a>
                    </div>
                    <%
                        delay += 0.2;

                        // Close row every 3 treatments or at the end
                        if ((i + 1) % 3 == 0 || i == treatmentCount - 1) {
                    %>
                </div>
                <%
                        }
                    }
                %>

                <%
                } else {
                %>
                <div class="row">
                    <div class="col-md-12 col-sm-12 text-center">
                        <div class="alert alert-info">
                            <i class="fa fa-info-circle"></i>
                            <strong>No treatments available at the moment.</strong>
                            <p>Please check back later or contact the administrator for more information.</p>
                        </div>
                    </div>
                </div>
                <% }%>

                <!-- Back to Dashboard -->
                <div class="row" style="margin-top: 30px;">
                    <div class="col-md-12 text-center">
                        <a href="<%= request.getContextPath()%>/CounterStaffServletJam?action=dashboard" class="section-btn btn btn-default">
                            <i class="fa fa-arrow-left"></i> Back to Dashboard
                        </a>
                    </div>
                </div>
            </div>
        </section>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>

        <script>
            // Counter staff specific JavaScript for treatments
            $(document).ready(function () {
                console.log('Counter Staff Treatments page loaded successfully');

                // Add click tracking for treatment views
                $('.clickable-treatment').click(function () {
                    const treatmentId = $(this).closest('.treatments-thumb').data('treatment-id');
                    console.log('Counter Staff viewing treatment:', treatmentId);
                });
            });
        </script>

    </body>

</html>

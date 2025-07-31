<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="model.Treatment" %>
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

    List<Treatment> treatmentList = (List<Treatment>) request.getAttribute("treatmentList");
%>

<!DOCTYPE html>
<html lang="en">

    <head>
        <title>All Treatments - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
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
        <section id="treatments" data-stellar-background-ratio="2.5">
            <div class="container">
                <div class="row">

                    <div class="col-md-12 col-sm-12">
                        <!-- SECTION TITLE -->
                        <div class="section-title wow fadeInUp" data-wow-delay="0.1s">
                            <h2>All Available Treatments</h2>
                            <% if (treatmentList != null && !treatmentList.isEmpty()) {%>
                            <p>We offer <%= treatmentList.size()%> specialized treatment services</p>
                            <% } %>
                        </div>
                    </div>

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
                            <a href="<%= request.getContextPath()%>/TreatmentServlet?action=viewDetail&id=<%= treatment.getId()%>">

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

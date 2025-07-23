<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="model.Treatment" %>
<%
    List<Treatment> treatmentList = (List<Treatment>) request.getAttribute("treatmentList");
%>

<!DOCTYPE html>
<html lang="en">

<head>
    <title>All Treatments - APU Medical Center</title>
    <%@ include file="/includes/head.jsp" %>
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
                        <% if (treatmentList != null && !treatmentList.isEmpty()) { %>
                            <p>We offer <%= treatmentList.size() %> specialized treatment services</p>
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
                            String imagePath = treatment.getTreatmentPic();
                            if (imagePath == null || imagePath.trim().isEmpty()) {
                                imagePath = "default-treatment.jpg";
                            }
                %>
                    <div class="<%= colClass %>">
                        <!-- TREATMENT THUMB -->
                        <div class="treatments-thumb wow fadeInUp" data-wow-delay="<%= delay %>s" data-treatment-id="<%= treatment.getId() %>">
                            <div class="treatment-image clickable-treatment">
                                <img src="images/<%= imagePath %>" class="img-responsive" alt="<%= displayName %>">
                            </div>
                            <div class="treatments-info">
                                <h3>
                                    <span class="treatment-name clickable-treatment">
                                        <%= displayName %>
                                    </span>
                                </h3>
                                <p><%= shortDesc %></p>
                                <div class="treatment-meta">
                                    <% if (treatment.getBaseConsultationCharge() > 0) { %>
                                        <p class="treatment-price">
                                            <i class="fa fa-money"></i> 
                                            Base Consultation: RM <%= String.format("%.2f", treatment.getBaseConsultationCharge()) %>
                                        </p>
                                    <% } %>
                                </div>
                            </div>
                        </div>
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
                <% } %>

            </div>
        </div>
    </section>

    <%@ include file="/includes/footer.jsp" %>
    <%@ include file="/includes/scripts.jsp" %>

</body>

</html>

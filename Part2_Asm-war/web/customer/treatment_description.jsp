<%--<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>--%>
<%@ page import="java.util.List" %>
<%@ page import="model.Treatment" %>
<%@ page import="model.Prescription" %>
<%
    // Get the selected treatment from request attributes
//    Treatment selectedTreatment = (Treatment) request.getAttribute("selectedTreatment");
//    List<Prescription> prescriptions = (List<Prescription>) request.getAttribute("prescriptions");
//    List<Treatment> relatedTreatments = (List<Treatment>) request.getAttribute("relatedTreatments");
//    
//    // Get treatment ID from URL parameter as fallback
//    String treatmentIdParam = request.getParameter("id");
//    
//    // Validation: Check if we have a valid treatment
//    if (selectedTreatment == null && treatmentIdParam != null) {
//        // If servlet didn't populate selectedTreatment, we have an error state
//        // This would typically be handled by redirecting back to treatment list
//    }
%>

<%
    Treatment selectedTreatment = (Treatment) request.getAttribute("treatment");
    System.out.print(selectedTreatment);
    List<Prescription> prescriptions = (List<Prescription>) request.getAttribute("prescriptions");
    System.out.print(prescriptions);
%>


<!DOCTYPE html>
<html lang="en">

    <head>
        <% if (selectedTreatment != null) {
                String treatmentName = selectedTreatment.getName();
                if (treatmentName != null && treatmentName.contains("-")) {
                    treatmentName = treatmentName.substring(0, treatmentName.indexOf("-")).trim();
                }
        %>
        <title><%= treatmentName%> - APU Medical Center</title>
        <% } else { %>
        <title>Treatment Details - APU Medical Center</title>
        <% }%>
        <%@ include file="/includes/head.jsp" %>
    </head>

    <body id="top" data-spy="scroll" data-target=".navbar-collapse" data-offset="50">

        <%@ include file="/includes/preloader.jsp" %>
        <%@ include file="/includes/header.jsp" %>
        <%@ include file="/includes/navbar.jsp" %>

        <!-- TREATMENT DESCRIPTION -->
        <% if (selectedTreatment != null) {
                // Extract and validate treatment data
                String displayName = selectedTreatment.getName();
                if (displayName != null && displayName.contains("-")) {
                    displayName = displayName.substring(0, displayName.indexOf("-")).trim();
                }
                if (displayName == null || displayName.trim().isEmpty()) {
                    displayName = "Treatment Information";
                }

                String shortDesc = selectedTreatment.getShortDescription();
                if (shortDesc == null || shortDesc.trim().isEmpty()) {
                    shortDesc = "Treatment details available upon consultation.";
                }

                String longDesc = selectedTreatment.getLongDescription();
                if (longDesc == null || longDesc.trim().isEmpty()) {
                    longDesc = "Comprehensive treatment information will be provided during your consultation with our medical team.";
                }

                String imagePath = selectedTreatment.getTreatmentPic();
                if (imagePath == null || imagePath.trim().isEmpty()) {
                    imagePath = "/images/treatment/default-treatment.jpg";
                }

                double baseCharge = selectedTreatment.getBaseConsultationCharge();
                double followUpCharge = selectedTreatment.getFollowUpCharge();
        %>

        <section id="treatment-detail" data-stellar-background-ratio="0.5">
            <div class="container">
                <div class="row">

                    <div class="col-md-8 col-sm-7">
                        <!-- TREATMENT DETAIL THUMB -->
                        <div class="treatments-detail-thumb">
                            <div class="treatments-image">
                                <img src="images/treatment/<%= imagePath%>" class="img-responsive" alt="<%= displayName%>">
                            </div>
                            <h3><%= displayName%></h3>

                            <!-- Short Description -->
                            <p class="treatment-short-desc"><%= shortDesc%></p>

                            <!-- Long Description -->
                            <div class="treatment-long-description">
                                <%
                                    // Split long description into paragraphs for better formatting
                                    String[] paragraphs = longDesc.split("\\n\\s*\\n");
                                    for (String paragraph : paragraphs) {
                                        if (paragraph.trim().length() > 0) {
                                %>
                                <p><%= paragraph.trim()%></p>
                                <%
                                        }
                                    }
                                %>
                            </div>

                            <!-- Prescription Information -->
                            <% if (prescriptions != null && !prescriptions.isEmpty()) { %>
                            <h4>Common Prescriptions:</h4>
                            <div class="prescription-info">
                                <%
                                    String currentCondition = "";
                                    for (Prescription prescription : prescriptions) {
                                        String condition = prescription.getConditionName();
                                        String medication = prescription.getMedicationName();

                                        if (condition == null) {
                                            condition = "General Treatment";
                                        }
                                        if (medication == null) {
                                            medication = "As prescribed by doctor";
                                        }

                                        if (!condition.equals(currentCondition)) {
                                            if (!currentCondition.isEmpty()) {
                                %>
                                <br>
                                <%      }
                                    currentCondition = condition;
                                %>
                                <strong><%= condition%>:</strong> 
                                <%  } else { %>
                                , 
                                <%  }
                                %>
                                <%= medication%>
                                <% } %>
                            </div>
                            <% }%>

                            <!-- Action Buttons -->
                            <div class="treatment-actions" style="margin-top: 30px;">
                                <a href="<%= request.getContextPath()%>/AppointmentServlet?treatment_id=<%= selectedTreatment.getId()%>" class="section-btn btn btn-default btn-blue">
                                    <i class="fa fa-calendar"></i> Book Appointment
                                </a>
                                <a href="<%= request.getContextPath()%>/TreatmentServlet?action=viewAll" class="section-btn btn btn-default" style="margin-left: 15px;">
                                    <i class="fa fa-arrow-left"></i> Back to All Treatments
                                </a>
                            </div>
                        </div>
                    </div>

                    <div class="col-md-4 col-sm-5">
                        <div class="treatments-sidebar">
                            <div class="treatments-side-descriptions">

                                <!-- Consultation Charges -->
                                <h4>Consultation Charges:</h4>
                                <div class="consultation-charges">
                                    <% if (baseCharge > 0) {%>
                                    <p><strong>Base Consultation:</strong> RM <%= String.format("%.2f", baseCharge)%></p>
                                    <% } else { %>
                                    <p><strong>Base Consultation:</strong> Please contact for pricing</p>
                                    <% } %>

                                    <% if (followUpCharge > 0) {%>
                                    <p><strong>Follow-up Visit:</strong> RM <%= String.format("%.2f", followUpCharge)%></p>
                                    <% } else { %>
                                    <p><strong>Follow-up Visit:</strong> Please contact for pricing</p>
                                    <% } %>

                                    <p><em>Consultation rates may change depending on complexity of case.</em></p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <% } else { %>

        <!-- ERROR STATE - Treatment Not Found -->
        <section id="treatment-not-found" data-stellar-background-ratio="0.5">
            <div class="container">
                <div class="row">
                    <div class="col-md-12 text-center">
                        <div class="alert alert-warning" style="margin-top: 50px; margin-bottom: 50px;">
                            <h3><i class="fa fa-exclamation-triangle"></i> Treatment Not Found</h3>
                            <p>Sorry, the requested treatment information could not be found or is currently unavailable.</p>
                            <div style="margin-top: 30px;">
                                <a href="treatment.jsp" class="section-btn btn btn-default">
                                    <i class="fa fa-list"></i> View All Treatments
                                </a>
                                <a href="cust_homepage.jsp" class="section-btn btn btn-default" style="margin-left: 15px;">
                                    <i class="fa fa-home"></i> Back to Homepage
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <% }%>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>

    </body>

</html>

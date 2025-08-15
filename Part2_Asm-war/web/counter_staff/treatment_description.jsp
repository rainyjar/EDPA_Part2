<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="model.Treatment" %>
<%@ page import="model.Prescription" %>
<%@ page import="model.CounterStaff" %>

<%
    // Check if counter staff is logged in
    CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");
    System.out.println("Counter Staff Treatment Detail - Staff: " + loggedInStaff);

    if (loggedInStaff == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    } else {
        System.out.println("Counter Staff " + loggedInStaff.getName() + " viewing treatment details!");
    }

    Treatment selectedTreatment = (Treatment) request.getAttribute("treatment");
    List<Prescription> prescriptions = (List<Prescription>) request.getAttribute("prescriptions");
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Treatment Details - Counter Staff - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/staff.css">
        <style>
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

            .treatment-detail-header {
                background: linear-gradient(135deg, #2c2577 0%, #f41212 100%);
                color: white;
                padding: 60px 0 40px 0;
                margin-bottom: 30px;
            }

            .treatment-meta-staff {
                background: #f8f9fa;
                border-radius: 10px;
                padding: 20px;
                margin-bottom: 20px;
                border-left: 4px solid #2c2577;
            }

            .prescription-info {
                background: #e9f7ef;
                border-radius: 8px;
                padding: 15px;
                margin-top: 15px;
                border-left: 4px solid #2c2577;
            }

            .staff-action-buttons .btn {
                margin: 5px;
                padding: 12px 25px;
            }

            .btn-staff-primary {
                background: linear-gradient(135deg, #28a745, #20c997);
                border: none;
                color: white;
            }

            .btn-staff-primary:hover {
                background: linear-gradient(135deg, #218838, #1eb88a);
                transform: translateY(-2px);
            }
        </style>
    </head>

    <body id="top" data-spy="scroll" data-target=".navbar-collapse" data-offset="50">

        <%@ include file="/includes/preloader.jsp" %>
        <%@ include file="/includes/header.jsp" %>
        <%@ include file="/includes/navbar.jsp" %>

        <!-- TREATMENT DETAIL HEADER -->
        <section class="treatment-detail-header">
            <div class="container">
                <div class="row">
                    <div class="col-md-12">
                        <span class="staff-badge">
                            <i class="fa fa-user-md"></i> Counter Staff Access
                        </span>
                        <h2>Treatment Information</h2>
                        <p>Detailed treatment information for customer assistance</p>
                    </div>
                </div>
            </div>
        </section>

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

                String treatmentImagePath = selectedTreatment.getTreatmentPic();
                String treatmentPic = (treatmentImagePath != null && !treatmentImagePath.isEmpty())
                        ? (request.getContextPath() + "/ImageServlet?folder=treatment&file=" + treatmentImagePath)
                        : (request.getContextPath() + "/images/placeholder/default-treatment.jpg");

                double baseCharge = selectedTreatment.getBaseConsultationCharge();
                double followUpCharge = selectedTreatment.getFollowUpCharge();
        %>

        <section id="treatment-detail" style="background: white; padding: 40px 0;">
            <div class="container">
                <div class="row">

                    <div class="col-md-8 col-sm-7">
                        <!-- TREATMENT DETAIL THUMB -->
                        <div class="treatments-detail-thumb">
                            <div class="treatments-image">
                                <img src="<%=treatmentPic%>" class="img-responsive" alt="<%= treatmentPic%>" style="border-radius: 10px;">
                            </div>
                            
                            <div class="treatment-meta-staff">
                                <h3><i class="fa fa-stethoscope"></i> <%= displayName%></h3>
                                <p class="text-muted"><i class="fa fa-info-circle"></i> Staff Information Access</p>
                            </div>

                            <!-- Short Description -->
                            <div class="treatment-section">
                                <h4><i class="fa fa-file-text-o"></i> Quick Overview</h4>
                                <p class="treatment-short-desc"><%= shortDesc%></p>
                            </div>

                            <!-- Long Description -->
                            <div class="treatment-section">
                                <h4><i class="fa fa-list-alt"></i> Detailed Description</h4>
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
                            </div>

                            <!-- Prescription Information -->
                            <% if (prescriptions != null && !prescriptions.isEmpty()) { %>
                            <div class="treatment-section">
                                <h4><i class="fa fa-medkit"></i> Common Prescriptions</h4>
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
                            </div>
                            <% }%>

                            <!-- Staff Action Buttons -->
                            <div class="treatment-actions staff-action-buttons" style="margin-top: 30px;">
                                <a href="<%= request.getContextPath()%>/AppointmentServlet?action=book" class="section-btn btn btn-staff-primary">
                                    <i class="fa fa-calendar-plus-o"></i> Help Customer Book Appointment
                                </a>
                                <a href="<%= request.getContextPath()%>/TreatmentServlet?action=viewAll&role=staff" class="section-btn btn btn-default" style="margin-left: 15px;">
                                    <i class="fa fa-arrow-left"></i> Back to All Treatments
                                </a>
                            </div>
                        </div>
                    </div>

                    <div class="col-md-4 col-sm-5">
                        <div class="treatments-sidebar">
                            <!-- Consultation Charges -->
                            <div class="treatment-meta-staff">
                                <h4><i class="fa fa-money"></i> Consultation Charges</h4>
                                <div class="consultation-charges">
                                    <% if (baseCharge > 0) {%>
                                    <p><strong>Base Consultation:</strong><br>RM <%= String.format("%.2f", baseCharge)%></p>
                                    <% } else { %>
                                    <p><strong>Base Consultation:</strong><br>Please contact for pricing</p>
                                    <% } %>

                                    <% if (followUpCharge > 0) {%>
                                    <p><strong>Follow-up Visit:</strong><br>RM <%= String.format("%.2f", followUpCharge)%></p>
                                    <% } else { %>
                                    <p><strong>Follow-up Visit:</strong><br>Please contact for pricing</p>
                                    <% } %>

                                    <p class="text-muted"><em><i class="fa fa-info-circle"></i> Rates may vary based on case complexity.</em></p>
                                </div>
                            </div>

                            <!-- Staff Guidelines -->
                            <div class="treatment-meta-staff">
                                <h4><i class="fa fa-user-md"></i> Staff Guidelines</h4>
                                <ul class="list-unstyled">
                                    <li><i class="fa fa-check text-success"></i> Explain treatment benefits to customers</li>
                                    <li><i class="fa fa-check text-success"></i> Help with appointment booking</li>
                                    <li><i class="fa fa-check text-success"></i> Provide pricing information</li>
                                    <li><i class="fa fa-check text-success"></i> Answer basic questions</li>
                                    <li><i class="fa fa-info-circle text-info"></i> Refer complex queries to doctors</li>
                                </ul>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <% } else { %>

        <!-- ERROR STATE - Treatment Not Found -->
        <section id="treatment-not-found" style="background: white; padding: 60px 0;">
            <div class="container">
                <div class="row">
                    <div class="col-md-12 text-center">
                        <div class="alert alert-warning" style="margin-top: 50px; margin-bottom: 50px;">
                            <h3><i class="fa fa-exclamation-triangle"></i> Treatment Not Found</h3>
                            <p>Sorry, the requested treatment information could not be found or is currently unavailable.</p>
                            <div style="margin-top: 30px;">
                                <a href="<%= request.getContextPath()%>/TreatmentServlet?action=viewAll&role=staff" class="section-btn btn btn-default">
                                    <i class="fa fa-list"></i> View All Treatments
                                </a>
                                <a href="<%= request.getContextPath()%>/CounterStaffServletJam?action=dashboard" class="section-btn btn btn-default" style="margin-left: 15px;">
                                    <i class="fa fa-home"></i> Back to Dashboard
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

        <script>
            // Counter staff specific JavaScript for treatment details
            $(document).ready(function () {
                console.log('Counter Staff Treatment Detail page loaded successfully');
                
                // Add smooth scrolling for internal links
                $('a[href^="#"]').on('click', function(event) {
                    var target = $(this.getAttribute('href'));
                    if( target.length ) {
                        event.preventDefault();
                        $('html, body').stop().animate({
                            scrollTop: target.offset().top - 100
                        }, 1000);
                    }
                });
            });
        </script>

    </body>

</html>

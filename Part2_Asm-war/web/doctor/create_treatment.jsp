<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="model.Doctor" %>
<%
    Doctor doctor = (Doctor) session.getAttribute("doctor");
    if (doctor == null) {
        response.sendRedirect("../login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Create Treatment - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/css/user-reg-edit.css" />
    </head>
    <body class="doctor-theme">
        <%@ include file="/includes/header.jsp" %>
        <%@ include file="/includes/navbar.jsp" %>
        <div class="registration-container">
            <a href="${pageContext.request.contextPath}/TreatmentServlet?action=manage" class="back-btn" style="margin-top: 30px; margin-bottom: 30px">
                <i class="fa fa-arrow-left"></i> Back to Manage Treatments
            </a>

            <div class="registration-card">
                <div class="card-header doctor">
                    <h2>
                        <i class="fa fa-stethoscope role-icon"></i>
                        <span>Create New Treatment</span>
                    </h2>
                </div>

                <div class="form-container">
                    <!-- Success Message -->
                    <% if (request.getAttribute("success") != null) {%>
                    <div class="alert alert-success">
                        <i class="fa fa-check-circle"></i>
                        <%= request.getAttribute("success")%>
                    </div>
                    <% }%>

                    <!-- Error Message -->
                    <% if (request.getAttribute("error") != null) {%>
                    <div class="alert alert-error">
                        <i class="fa fa-exclamation-triangle"></i>
                        <%= request.getAttribute("error")%>
                    </div>
                    <% }%>

                    <form id="treatmentForm" method="post" enctype="multipart/form-data" action="${pageContext.request.contextPath}/TreatmentServlet" novalidate>
                        <input type="hidden" name="action" value="create">
                        
                        <!--Treatment Information Section -->
                        <div class="form-row">
                            <div class="form-group">
                                <label for="name">Treatment Name <span class="required">*</span></label>
                                <input type="text" id="name" name="name" class="form-control doctor" 
                                       placeholder="Enter treatment name" required>
                                <div class="invalid-feedback"></div>
                            </div>

                            <div class="form-group">
                                <label for="baseCharge">Base Consultation Charge (RM) <span class="required">*</span></label>
                                <input type="number" id="baseCharge" name="baseCharge" class="form-control doctor" 
                                       step="0.01" min="0" placeholder="0.00" required>
                                <div class="invalid-feedback"></div>
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label for="followUpCharge">Follow-up Charge (RM) <span class="required">*</span></label>
                                <input type="number" id="followUpCharge" name="followUpCharge" class="form-control doctor" 
                                       step="0.01" min="0" placeholder="0.00" required>
                                <div class="invalid-feedback"></div>
                            </div>
                        </div>

                        <div class="form-group">
                            <label for="shortDesc">Short Description <span class="required">*</span></label>
                            <textarea id="shortDesc" name="shortDesc" class="form-control doctor" style="resize: none;" rows="3" 
                                      placeholder="Brief description of the treatment" required></textarea>
                            <div class="invalid-feedback"></div>
                        </div>

                        <div class="form-group">
                            <label for="longDesc">Long Description <span class="required">*</span></label>
                            <textarea id="longDesc" name="longDesc" class="form-control doctor" style="resize: none;" rows="5" 
                                      placeholder="Detailed description of the treatment" required></textarea>
                            <div class="invalid-feedback"></div>
                        </div>

                        <!-- Treatment Picture Section -->
                        <div class="form-group">
                            <label for="treatmentPic">Treatment Image <span class="required">*</span></label>

                            <div class="file-upload">
                                <div class="file-upload-wrapper">
                                    <input type="file" class="form-control" id="treatmentPic" name="treatmentPic" accept="image/*" required>
                                    <label for="treatmentPic" class="file-upload-btn" id="fileLabel">
                                        <i class="fa fa-cloud-upload"></i>
                                        <span>Choose Treatment Image</span>
                                    </label>
                                </div>
                                <div class="invalid-feedback" id="treatmentPicError" style="display: block;"></div>
                            </div>
                        </div>

                        <hr>

                        <!-- Prescriptions Section -->
                        <div class="form-group">
                            <h5><i class="fa fa-pills"></i> Prescriptions</h5>
                            <p class="text-muted">Add prescriptions for this treatment</p>
                            
                            <div id="prescriptionContainer">
                                <div class="prescription-row">
                                    <div class="form-row">
                                        <div class="form-group">
                                            <label>Condition Name</label>
                                            <input type="text" class="form-control doctor" name="conditionName" 
                                                   placeholder="e.g., Hypertension">
                                            <div class="invalid-feedback"></div>
                                        </div>
                                        <div class="form-group">
                                            <label>Medication Name</label>
                                            <input type="text" class="form-control doctor" name="medicationName" 
                                                   placeholder="e.g., Lisinopril 10mg">
                                            <div class="invalid-feedback"></div>
                                        </div>
                                    </div>
                                    <div class="form-group" style="text-align: center;">
                                        <button type="button" class="btn btn-danger remove-prescription" 
                                                onclick="removePrescription(this)" style="display: none;">
                                            <i class="fa fa-trash"></i> Remove
                                        </button>
                                    </div>
                                </div>
                            </div>
                            
                            <button type="button" class="btn btn-secondary" onclick="addPrescription()">
                                <i class="fa fa-plus"></i> Add Prescription
                            </button>
                        </div>

                        <button type="submit" class="submit-btn doctor" id="submitBtn">
                            <span class="btn-text">
                                <i class="fa fa-save"></i>
                                Create Treatment
                            </span>
                        </button>
                    </form>
                </div>
            </div>
        </div>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>

        <script src="${pageContext.request.contextPath}/js/jquery.min.js"></script>
        <script src="${pageContext.request.contextPath}/js/validate-treatment.js"></script>
        <script>
            // Auto-hide alerts after 5 seconds
            setTimeout(function() {
                $('.alert').fadeOut('slow');
            }, 5000);

            // Clear form after successful creation
            <% if (request.getAttribute("success") != null) {%>
            $(document).ready(function() {
                // Clear the form after successful creation
                $('#treatmentForm')[0].reset();
                
                // Reset file input label
                $('#fileLabel span').text('Choose Treatment Image');
                
                // Clear prescription rows except the first one
                $('#prescriptionContainer .prescription-row').not(':first').remove();
                $('.remove-prescription').hide();
                
                // Reset validation classes
                $('.form-control').removeClass('is-valid is-invalid');
                $('.invalid-feedback').hide();
                
                console.log('Form cleared after successful treatment creation');
            });
            <% }%>
        </script>
    </body>
</html>

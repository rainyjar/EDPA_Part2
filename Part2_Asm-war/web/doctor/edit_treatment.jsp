<%@page import="java.util.Set"%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="model.Treatment" %>
<%@ page import="model.Prescription" %>
<%@ page import="model.Doctor" %>
<%
    Doctor doctor = (Doctor) session.getAttribute("doctor");
    if (doctor == null) {
        response.sendRedirect("../login.jsp");
        return;
    }
    
    Treatment treatment = (Treatment) request.getAttribute("treatment");
    List<Prescription> prescriptions = (List<Prescription>) request.getAttribute("prescriptions");
    
    if (treatment == null) {
        response.sendRedirect(request.getContextPath() + "/TreatmentServlet?action=manage");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Edit Treatment - APU Medical Center</title>
        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/css/user-reg-edit.css" />
        <style>
            /* Multi-select dropdown styling */
            select[multiple] {
                height: 120px !important;
                border: 2px solid #ddd;
                border-radius: 5px;
                padding: 8px;
                font-size: 14px;
            }
            select[multiple] option {
                padding: 5px 8px;
                border-bottom: 1px solid #eee;
            }
            select[multiple] option:hover {
                background-color: #667eea;
                color: white;
            }
            select[multiple] option:checked {
                background-color: #667eea;
                color: white;
                font-weight: bold;
            }
        </style>
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
                        <i class="fa fa-edit role-icon"></i>
                        <span>Edit Treatment</span>
                    </h2>
                </div>

                <div class="form-container">
                    <!-- Success Message -->
                    <% 
                    String successMsg = (String) request.getAttribute("success");
                    if (successMsg == null) {
                        successMsg = request.getParameter("success");
                    }
                    if (successMsg != null) {
                    %>
                    <div class="alert alert-success" id="successAlert">
                        <i class="fa fa-check-circle"></i>
                        <%= successMsg %>
                    </div>
                    <% } %>

                    <!-- Error Message -->
                    <% 
                    String errorMsg = (String) request.getAttribute("error");
                    if (errorMsg == null) {
                        errorMsg = request.getParameter("error");
                    }
                    if (errorMsg != null) {
                    %>
                    <div class="alert alert-error" id="errorAlert">
                        <i class="fa fa-exclamation-triangle"></i>
                        <%= errorMsg %>
                    </div>
                    <% } %>

                    <!-- Prescription Success Message -->
                    <% 
                    String prescriptionSuccessMsg = request.getParameter("prescriptionSuccess");
                    if (prescriptionSuccessMsg != null) {
                    %>
                    <div class="alert alert-success" id="prescriptionSuccessAlert">
                        <i class="fa fa-check-circle"></i>
                        <%= prescriptionSuccessMsg %>
                    </div>
                    <% } %>

                    <!-- Prescription Error Message -->
                    <% 
                    String prescriptionErrorMsg = request.getParameter("prescriptionError");
                    if (prescriptionErrorMsg != null) {
                    %>
                    <div class="alert alert-error" id="prescriptionErrorAlert">
                        <i class="fa fa-exclamation-triangle"></i>
                        <%= prescriptionErrorMsg %>
                    </div>
                    <% } %>

                    <!-- Treatment Information Form -->
                    <form id="treatmentForm" method="post" enctype="multipart/form-data" action="${pageContext.request.contextPath}/TreatmentServlet" novalidate>
                        <input type="hidden" name="action" value="update">
                        <input type="hidden" name="id" value="<%= treatment.getId() %>">
                        
                        <!--Treatment Information Section -->
                        <div class="form-row">
                            <div class="form-group">
                                <label for="name">Treatment Name <span class="required">*</span></label>
                                <input type="text" id="name" name="name" class="form-control doctor" 
                                       value="<%= treatment.getName() != null ? treatment.getName() : "" %>" required>
                                <div class="invalid-feedback"></div>
                            </div>

                            <div class="form-group">
                                <label for="baseCharge">Base Consultation Charge (RM) <span class="required">*</span></label>
                                <input type="number" id="baseCharge" name="baseCharge" class="form-control doctor" 
                                       step="0.01" min="0" value="<%= treatment.getBaseConsultationCharge() %>" required>
                                <div class="invalid-feedback"></div>
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label for="followUpCharge">Follow-up Charge (RM) <span class="required">*</span></label>
                                <input type="number" id="followUpCharge" name="followUpCharge" class="form-control doctor" 
                                       step="0.01" min="0" value="<%= treatment.getFollowUpCharge() %>" required>
                                <div class="invalid-feedback"></div>
                            </div>
                        </div>

                        <div class="form-group">
                            <label for="shortDesc">Short Description <span class="required">*</span></label>
                            <textarea id="shortDesc" name="shortDesc" class="form-control doctor" style="resize: none;" rows="3" required><%= treatment.getShortDescription() != null ? treatment.getShortDescription() : "" %></textarea>
                            <div class="invalid-feedback"></div>
                        </div>

                        <div class="form-group">
                            <label for="longDesc">Long Description <span class="required">*</span></label>
                            <textarea id="longDesc" name="longDesc" class="form-control doctor" style="resize: none;" rows="5" required><%= treatment.getLongDescription() != null ? treatment.getLongDescription() : "" %></textarea>
                            <div class="invalid-feedback"></div>
                        </div>

                        <!-- Doctor Assignment Section -->
                        <div class="form-group">
                            <label for="assignedDoctors">Assign Doctors <span class="required">*</span></label>
                            <select id="assignedDoctors" name="assignedDoctors" class="form-control doctor" multiple required>
                                <% 
                                List<model.Doctor> allDoctors = (List<model.Doctor>) request.getAttribute("allDoctors");
                                Set<model.Doctor> currentDoctors = treatment.getDoctors();
                                if (allDoctors != null && !allDoctors.isEmpty()) {
                                    for (model.Doctor doc : allDoctors) {
                                        boolean isSelected = currentDoctors != null && currentDoctors.contains(doc);
                                %>
                                    <option value="<%= doc.getId() %>" <%= isSelected ? "selected" : "" %>>
                                        Dr. <%= doc.getName() %> - <%= doc.getSpecialization() != null ? doc.getSpecialization() : "General" %>
                                    </option>
                                <% 
                                    }
                                } else {
                                %>
                                    <option value="" disabled>No doctors available</option>
                                <% } %>
                            </select>
                            <small class="form-text text-muted">
                                <i class="fa fa-info-circle"></i> Hold Ctrl (Cmd on Mac) to select multiple doctors. Currently assigned: 
                                <% if (currentDoctors != null && !currentDoctors.isEmpty()) { %>
                                    <%= currentDoctors.size() %> doctor(s)
                                <% } else { %>
                                    No doctors assigned
                                <% } %>
                            </small>
                            <div class="invalid-feedback"></div>
                        </div>

                        <!-- Treatment Picture Section -->
                        <div class="form-group">
                            <label for="treatmentPic">Treatment Image</label>
                            <div class="file-upload">
                                <div class="file-upload-wrapper">
                                    <input type="file" class="form-control" id="treatmentPic" name="treatmentPic" accept="image/*">
                                    <label for="treatmentPic" class="file-upload-btn" id="fileLabel">
                                        <i class="fa fa-cloud-upload"></i>
                                        <span>Choose New Treatment Image</span>
                                    </label>
                                </div>
                                <div class="invalid-feedback" id="treatmentPicError" style="display: block;"></div>
                                <% if (treatment.getTreatmentPic() != null && !treatment.getTreatmentPic().isEmpty()) { %>
                                <small class="text-muted">Current image: <%= treatment.getTreatmentPic() %></small>
                                <% } %>
                            </div>
                        </div>

                        <hr>

                        <!-- Add New Prescriptions Section -->
                        <div class="form-group">
                            <h5><i class="fa fa-plus"></i> Add New Prescriptions</h5>
                            
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
                                Update Treatment
                            </span>
                        </button>
                    </form>
                </div>
            </div>

            <!-- Existing Prescriptions Section (Separate from Form) -->
            <div class="registration-card" style="margin-top: 30px;">
                <div class="card-header doctor">
                    <h3>
                        <i class="fa fa-list-ul"></i>
                        <span>Existing Prescriptions</span>
                        <%
                            int totalPrescriptions = (prescriptions != null) ? prescriptions.size() : 0;
                        %>
                        <span style="background: rgba(255,255,255,0.2); padding: 5px 10px; border-radius: 15px; font-size: 14px; margin-left: 10px;">
                            <%= totalPrescriptions %> Total
                        </span>
                    </h3>
                </div>

                <div class="form-container">
                    <%
                        if (prescriptions != null && !prescriptions.isEmpty()) {
                            for (int i = 0; i < prescriptions.size(); i++) {
                                Prescription prescription = prescriptions.get(i);
                    %>
                    <div class="prescription-item" style="border: 1px solid #ddd; padding: 20px; margin-bottom: 20px; border-radius: 10px; background: #f9f9f9; position: relative;">
                        <!-- Prescription Number Badge -->
                        <div style="position: absolute; top: -10px; left: 20px; background: #2c2577; color: white; padding: 8px 15px; border-radius: 20px; font-weight: 600; font-size: 14px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                            <i class="fa fa-hashtag"></i> Prescription <%= (i + 1) %>
                        </div>
                        
                        <form action="<%= request.getContextPath()%>/TreatmentServlet" method="post" style="margin: 0; margin-top: 15px;">
                            <input type="hidden" name="action" value="updatePrescription">
                            <input type="hidden" name="prescriptionId" value="<%= prescription.getId() %>">
                            <input type="hidden" name="treatmentId" value="<%= treatment.getId() %>">
                            
                            <div class="form-row">
                                <div class="form-group">
                                    <label style="font-weight: 600; color: #2c2577; margin-bottom: 10px; display: block; font-size: 14px;">
                                        <i class="fa fa-heartbeat"></i> Condition Name
                                    </label>
                                    <input type="text" class="form-control doctor" name="conditionName" 
                                           value="<%= prescription.getConditionName() != null ? prescription.getConditionName() : "" %>" 
                                           style="padding: 12px; border: 2px solid #ddd; border-radius: 8px;" required>
                                </div>
                                
                                <div class="form-group">
                                    <label style="font-weight: 600; color: #2c2577; margin-bottom: 10px; display: block; font-size: 14px;">
                                        <i class="fa fa-medkit"></i> Medication Name
                                    </label>
                                    <input type="text" class="form-control doctor" name="medicationName" 
                                           value="<%= prescription.getMedicationName() != null ? prescription.getMedicationName() : "" %>" 
                                           style="padding: 12px; border: 2px solid #ddd; border-radius: 8px;" required>
                                </div>
                            </div>
                            
                            <div style="display: flex; gap: 15px; margin-top: 20px; justify-content: center;">
                                <button type="submit" class="btn btn-success" style="flex: 0 0 auto; padding: 12px 25px; font-weight: 600;">
                                    <i class="fa fa-save"></i> Update Prescription
                                </button>
                                <a href="<%= request.getContextPath()%>/TreatmentServlet?action=deletePrescription&prescriptionId=<%= prescription.getId() %>&treatmentId=<%= treatment.getId() %>" 
                                   class="btn btn-danger" style="flex: 0 0 auto; padding: 12px 25px; text-decoration: none; color: white; font-weight: 600;"
                                   onclick="return confirm('Are you sure you want to delete Prescription <%= (i + 1) %>?\n\nCondition: <%= prescription.getConditionName() %>\nMedication: <%= prescription.getMedicationName() %>\n\nThis action cannot be undone.')">
                                    <i class="fa fa-trash"></i> Delete Prescription
                                </a>
                            </div>
                        </form>
                    </div>
                    <%
                            }
                        } else {
                    %>
                    <div class="alert alert-info" style="padding: 25px; background: linear-gradient(135deg, #d1ecf1 0%, #bee5eb 100%); border: 2px solid #86cfda; border-radius: 10px; color: #0c5460; text-align: center; font-size: 16px;">
                        <i class="fa fa-info-circle" style="font-size: 24px; margin-bottom: 10px; display: block;"></i>
                        <strong>No prescriptions found for this treatment.</strong>
                        <br><small>You can add new prescriptions using the form above.</small>
                    </div>
                    <% } %>
                </div>
            </div>
        </div>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>

        <script src="${pageContext.request.contextPath}/js/jquery.min.js"></script>
        <script src="${pageContext.request.contextPath}/js/validate-treatment.js"></script>
        <script>
            // Override form validation for edit mode (file upload is optional)
            $('#treatmentForm').off('submit').on('submit', function (e) {
                console.log('Edit treatment form submitted');
                let isValid = validateEditTreatmentForm();
                
                if (!isValid) {
                    e.preventDefault();
                    console.log('Edit form validation failed - preventing submission');
                    scrollToFirstError();
                } else {
                    console.log('Edit form validation passed - submitting');
                    showLoadingState('#submitBtn', 'Updating Treatment...');
                }
            });

            function validateEditTreatmentForm() {
                console.log('Starting edit form validation');
                let isValid = true;

                // Reset validation styles
                $('.form-control').removeClass('is-invalid is-valid');
                $('.invalid-feedback').empty().hide();

                // Validate treatment name
                const name = $('#name').val().trim();
                if (!name) {
                    showError('#name', 'Treatment name is required');
                    isValid = false;
                } else if (name.length < 2) {
                    showError('#name', 'Treatment name must be at least 2 characters');
                    isValid = false;
                } else {
                    showValid('#name');
                }

                // Validate short description
                const shortDesc = $('#shortDesc').val().trim();
                if (!shortDesc) {
                    showError('#shortDesc', 'Short description is required');
                    isValid = false;
                } else if (shortDesc.length < 10) {
                    showError('#shortDesc', 'Short description must be at least 10 characters');
                    isValid = false;
                } else {
                    showValid('#shortDesc');
                }

                // Validate long description (required)
                const longDesc = $('#longDesc').val().trim();
                if (!longDesc) {
                    showError('#longDesc', 'Long description is required');
                    isValid = false;
                } else if (longDesc.length > 2000) {
                    showError('#longDesc', 'Long description must be less than 2000 characters');
                    isValid = false;
                } else {
                    showValid('#longDesc');
                }

                // Validate base charge
                const baseCharge = $('#baseCharge').val();
                if (!baseCharge) {
                    showError('#baseCharge', 'Base consultation charge is required');
                    isValid = false;
                } else if (parseFloat(baseCharge) < 0) {
                    showError('#baseCharge', 'Base charge cannot be negative');
                    isValid = false;
                } else if (parseFloat(baseCharge) > 10000) {
                    showError('#baseCharge', 'Base charge seems unusually high (max RM 10,000)');
                    isValid = false;
                } else {
                    showValid('#baseCharge');
                }

                // Validate follow-up charge
                const followUpCharge = $('#followUpCharge').val();
                if (!followUpCharge) {
                    showError('#followUpCharge', 'Follow-up charge is required');
                    isValid = false;
                } else if (parseFloat(followUpCharge) < 0) {
                    showError('#followUpCharge', 'Follow-up charge cannot be negative');
                    isValid = false;
                } else if (parseFloat(followUpCharge) > 10000) {
                    showError('#followUpCharge', 'Follow-up charge seems unusually high (max RM 10,000)');
                    isValid = false;
                } else {
                    showValid('#followUpCharge');
                }

                // Validate treatment image (optional for edit)
                const treatmentPic = $('#treatmentPic')[0].files[0];
                if (treatmentPic) {
                    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
                    const maxSize = 5 * 1024 * 1024;

                    if (!allowedTypes.includes(treatmentPic.type)) {
                        showError('#treatmentPic', 'Only JPEG, PNG, and GIF images are allowed');
                        isValid = false;
                    } else if (treatmentPic.size > maxSize) {
                        showError('#treatmentPic', 'Image size must be less than 5MB');
                        isValid = false;
                    } else {
                        showValid('#treatmentPic');
                    }
                }

                // Validate new prescriptions (if any)
                const prescriptionRows = $('.prescription-row');
                let prescriptionErrors = 0;

                prescriptionRows.each(function() {
                    const conditionName = $(this).find('input[name="conditionName"]').val().trim();
                    const medicationName = $(this).find('input[name="medicationName"]').val().trim();

                    // Both must be filled or both must be empty
                    if (conditionName || medicationName) {
                        // If one field has content, both must have content
                        if (!conditionName || !medicationName) {
                            prescriptionErrors++;
                            if (!conditionName) {
                                showError($(this).find('input[name="conditionName"]')[0], 'Condition name is required if medication is provided');
                            }
                            if (!medicationName) {
                                showError($(this).find('input[name="medicationName"]')[0], 'Medication name is required if condition is provided');
                            }
                        } else {
                            // Both fields have content - validate length
                            if (conditionName.length >= 2 && medicationName.length >= 2) {
                                showValid($(this).find('input[name="conditionName"]')[0]);
                                showValid($(this).find('input[name="medicationName"]')[0]);
                            } else {
                                prescriptionErrors++;
                                if (conditionName.length < 2) {
                                    showError($(this).find('input[name="conditionName"]')[0], 'Condition name must be at least 2 characters');
                                }
                                if (medicationName.length < 2) {
                                    showError($(this).find('input[name="medicationName"]')[0], 'Medication name must be at least 2 characters');
                                }
                            }
                        }
                    } else {
                        // Both fields are empty - this is okay, clear any validation states
                        $(this).find('input[name="conditionName"]').removeClass('is-invalid is-valid');
                        $(this).find('input[name="medicationName"]').removeClass('is-invalid is-valid');
                        $(this).find('.invalid-feedback').hide();
                    }
                });

                if (prescriptionErrors > 0) {
                    isValid = false;
                }

                console.log('Edit validation result:', isValid ? 'PASSED' : 'FAILED');
                console.log('Prescription errors:', prescriptionErrors);

                return isValid;
            }

            // Auto-hide alerts after 5 seconds
            $(document).ready(function() {
                setTimeout(function() {
                    $('#successAlert, #errorAlert, #prescriptionSuccessAlert, #prescriptionErrorAlert').fadeOut('slow');
                }, 5000);
            });
        </script>
    </body>
</html>

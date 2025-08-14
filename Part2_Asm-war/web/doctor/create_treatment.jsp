<%@ page contentType="text/html" pageEncoding="UTF-8"%>
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
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Create Treatment - Healthcare System</title>
    
    <!-- Bootstrap CSS -->
    <link rel="stylesheet" href="../css/bootstrap.min.css">
    <link rel="stylesheet" href="../css/font-awesome.min.css">
    <link rel="stylesheet" href="../css/animate.css">
    <link rel="stylesheet" href="../css/templatemo-misc.css">
    <link rel="stylesheet" href="../css/templatemo-style.css">
</head>
<body>
    
    <!-- Include header -->
    <%@ include file="../includes/header.jsp" %>
    
    <section class="content-section" style="padding: 60px 0;">
        <div class="container">
            <div class="row">
                <div class="col-md-12">
                    <div class="section-title">
                        <h2><i class="fa fa-plus"></i> Create New Treatment</h2>
                        <p>Add a new treatment with prescriptions</p>
                    </div>
                </div>
            </div>

            <!-- Success/Error Messages -->
            <% if (request.getAttribute("success") != null) { %>
                <div class="alert alert-success alert-dismissible">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <i class="fa fa-check-circle"></i> <%= request.getAttribute("success") %>
                </div>
            <% } %>
            
            <% if (request.getAttribute("error") != null) { %>
                <div class="alert alert-danger alert-dismissible">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <i class="fa fa-exclamation-triangle"></i> <%= request.getAttribute("error") %>
                </div>
            <% } %>

            <div class="row">
                <div class="col-md-8 offset-md-2">
                    <div class="card">
                        <div class="card-header">
                            <h4><i class="fa fa-stethoscope"></i> Treatment Information</h4>
                        </div>
                        <div class="card-body">
                            <form action="<%= request.getContextPath()%>/TreatmentServlet" method="post" id="treatmentForm">
                                <input type="hidden" name="action" value="create">
                                
                                <!-- Treatment Basic Info -->
                                <div class="form-group">
                                    <label for="name"><i class="fa fa-tag"></i> Treatment Name *</label>
                                    <input type="text" class="form-control" id="name" name="name" required 
                                           placeholder="Enter treatment name">
                                </div>

                                <div class="form-group">
                                    <label for="shortDesc"><i class="fa fa-file-text-o"></i> Short Description *</label>
                                    <textarea class="form-control" id="shortDesc" name="shortDesc" rows="3" required 
                                              placeholder="Brief description of the treatment"></textarea>
                                </div>

                                <div class="form-group">
                                    <label for="longDesc"><i class="fa fa-file-text"></i> Long Description</label>
                                    <textarea class="form-control" id="longDesc" name="longDesc" rows="5" 
                                              placeholder="Detailed description of the treatment"></textarea>
                                </div>

                                <div class="row">
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label for="baseCharge"><i class="fa fa-money"></i> Base Consultation Charge (RM) *</label>
                                            <input type="number" class="form-control" id="baseCharge" name="baseCharge" 
                                                   step="0.01" min="0" required placeholder="0.00">
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label for="followUpCharge"><i class="fa fa-refresh"></i> Follow-up Charge (RM) *</label>
                                            <input type="number" class="form-control" id="followUpCharge" name="followUpCharge" 
                                                   step="0.01" min="0" required placeholder="0.00">
                                        </div>
                                    </div>
                                </div>

                                <div class="form-group">
                                    <label for="treatmentPic"><i class="fa fa-image"></i> Treatment Image URL</label>
                                    <input type="text" class="form-control" id="treatmentPic" name="treatmentPic" 
                                           placeholder="URL to treatment image">
                                </div>

                                <hr>

                                <!-- Prescriptions Section -->
                                <div class="form-group">
                                    <h5><i class="fa fa-pills"></i> Prescriptions</h5>
                                    <p class="text-muted">Add prescriptions for this treatment</p>
                                    
                                    <div id="prescriptionContainer">
                                        <div class="prescription-row">
                                            <div class="row">
                                                <div class="col-md-5">
                                                    <div class="form-group">
                                                        <label>Condition Name</label>
                                                        <input type="text" class="form-control" name="conditionName" 
                                                               placeholder="e.g., Hypertension">
                                                    </div>
                                                </div>
                                                <div class="col-md-5">
                                                    <div class="form-group">
                                                        <label>Medication Name</label>
                                                        <input type="text" class="form-control" name="medicationName" 
                                                               placeholder="e.g., Lisinopril 10mg">
                                                    </div>
                                                </div>
                                                <div class="col-md-2">
                                                    <div class="form-group">
                                                        <label>&nbsp;</label>
                                                        <button type="button" class="btn btn-danger btn-block remove-prescription" 
                                                                onclick="removePrescription(this)" style="display: none;">
                                                            <i class="fa fa-trash"></i>
                                                        </button>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    
                                    <button type="button" class="btn btn-secondary" onclick="addPrescription()">
                                        <i class="fa fa-plus"></i> Add Prescription
                                    </button>
                                </div>

                                <hr>

                                <!-- Action Buttons -->
                                <div class="form-group text-center">
                                    <a href="<%= request.getContextPath()%>/TreatmentServlet?action=manage" 
                                       class="btn btn-secondary">
                                        <i class="fa fa-arrow-left"></i> Back to Manage
                                    </a>
                                    <button type="submit" class="btn btn-primary">
                                        <i class="fa fa-save"></i> Create Treatment
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Include footer -->
    <%@ include file="../includes/footer.jsp" %>
    
    <!-- Scripts -->
    <%@ include file="../includes/scripts.jsp" %>

    <script>
        function addPrescription() {
            const container = document.getElementById('prescriptionContainer');
            const prescriptionRow = document.createElement('div');
            prescriptionRow.className = 'prescription-row';
            prescriptionRow.innerHTML = `
                <div class="row">
                    <div class="col-md-5">
                        <div class="form-group">
                            <label>Condition Name</label>
                            <input type="text" class="form-control" name="conditionName" 
                                   placeholder="e.g., Hypertension">
                        </div>
                    </div>
                    <div class="col-md-5">
                        <div class="form-group">
                            <label>Medication Name</label>
                            <input type="text" class="form-control" name="medicationName" 
                                   placeholder="e.g., Lisinopril 10mg">
                        </div>
                    </div>
                    <div class="col-md-2">
                        <div class="form-group">
                            <label>&nbsp;</label>
                            <button type="button" class="btn btn-danger btn-block remove-prescription" 
                                    onclick="removePrescription(this)">
                                <i class="fa fa-trash"></i>
                            </button>
                        </div>
                    </div>
                </div>
            `;
            container.appendChild(prescriptionRow);
            updateRemoveButtons();
        }

        function removePrescription(button) {
            const prescriptionRow = button.closest('.prescription-row');
            prescriptionRow.remove();
            updateRemoveButtons();
        }

        function updateRemoveButtons() {
            const rows = document.querySelectorAll('.prescription-row');
            rows.forEach((row, index) => {
                const removeBtn = row.querySelector('.remove-prescription');
                if (rows.length > 1) {
                    removeBtn.style.display = 'block';
                } else {
                    removeBtn.style.display = 'none';
                }
            });
        }

        // Form validation
        document.getElementById('treatmentForm').addEventListener('submit', function(e) {
            const name = document.getElementById('name').value.trim();
            const shortDesc = document.getElementById('shortDesc').value.trim();
            const baseCharge = document.getElementById('baseCharge').value;
            const followUpCharge = document.getElementById('followUpCharge').value;

            if (!name || !shortDesc || !baseCharge || !followUpCharge) {
                e.preventDefault();
                alert('Please fill in all required fields.');
                return false;
            }

            if (parseFloat(baseCharge) < 0 || parseFloat(followUpCharge) < 0) {
                e.preventDefault();
                alert('Charges cannot be negative.');
                return false;
            }
        });

        // Auto-hide alerts after 5 seconds
        setTimeout(function() {
            $('.alert').fadeOut('slow');
        }, 5000);
    </script>
</body>
</html>

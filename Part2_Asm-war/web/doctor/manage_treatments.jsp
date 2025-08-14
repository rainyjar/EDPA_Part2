<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="model.Treatment" %>
<%@ page import="model.Doctor" %>
<%
     Doctor doctor = (Doctor) session.getAttribute("doctor");
     if (doctor == null) {
        response.sendRedirect("../login.jsp");
        return;
    }
    List<Treatment> treatmentList = (List<Treatment>) request.getAttribute("treatmentList");

%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Manage Treatments - AMC Healthcare System</title>

        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manager-homepage.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manage-staff.css">

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
                            <i class="fa fa-stethoscope" style="color:white"></i>
                            <span style="color:white">Manage Treatments</span>
                        </h1>
                        <p class="lead wow fadeInUp" data-wow-delay="0.2s" style="color: whitesmoke">
                            Create, edit, and delete treatments with their prescriptions
                        </p>
                        <nav aria-label="breadcrumb" class="wow fadeInUp" data-wow-delay="0.3s">
                            <ol class="breadcrumb" style="background: transparent; margin: 0;">
                                <li class="breadcrumb-item">
                                    <!--return back to homepage-->
                                    <a href="<%= request.getContextPath()%>/DoctorHomepageServlet" style="color: rgba(255,255,255,0.8);">Dashboard</a> 
                                </li>
                                <li class="breadcrumb-item active" style="color: white;">Manage Treatments</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>
        </section>

        <section style="padding: 40px 0; background: #f5f5f5;">
            <div class="container">
                <!-- Success/Error Messages -->
                <% if (request.getAttribute("success") != null) {%>
                <div class="alert alert-success alert-dismissible">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <i class="fa fa-check-circle"></i> <%= request.getAttribute("success")%>
                </div>
                <% } %>

                <% if (request.getAttribute("error") != null) {%>
                <div class="alert alert-danger alert-dismissible">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <i class="fa fa-exclamation-triangle"></i> <%= request.getAttribute("error")%>
                </div>
                <% }%>

                <!-- SEARCH AND FILTER SECTION -->


                <!-- TREATMENT MANAGEMENT SECTION -->
                <div class="staff-management-section wow fadeInUp" data-wow-delay="0.4s">
                    <div class="d-flex justify-content-between align-items-center mb-4">
                        <h3><i class="fa fa-list"></i> Treatment Directory</h3>
                        <div>
                            <a href="<%= request.getContextPath()%>/TreatmentServlet?action=createForm" class="add-customer-btn">
                                <i class="fa fa-plus"></i> Add Treatment
                            </a>
                        </div>
                    </div>

                    <!-- Treatments Table -->
                    <div class="staff-table">
                        <%  if (treatmentList != null && !treatmentList.isEmpty()) { %>

                                    <table class="table table-hover">
                                        <thead >
                                            <tr>
                                                <th>ID</th>
                                                <th>Treatment Name</th>
                                                <th>Short Description</th>
                                                <th>Base Charge (RM)</th>
                                                <th>Follow-up Charge (RM)</th>
                                                <th>Prescriptions</th>
                                                <th>Actions</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <%
                                                //  if (treatmentList != null && !treatmentList.isEmpty()) {
                                                //    for (int i = 0; i < treatmentList.size(); i++) {
                                                //      Treatment treatment = treatmentList.get(i);
                                                for (Treatment treatment : treatmentList) {
                                            %>
                                            <tr>
                                                <td><%= treatment.getId()%></td>
                                                <td><strong><%= treatment.getName() != null ? treatment.getName() : "N/A"%></strong></td>
                                                <td>
                                                    <%
                                                        String shortDesc = treatment.getShortDescription();
                                                        if (shortDesc != null && shortDesc.length() > 100) {
                                                            out.print(shortDesc.substring(0, 100) + "...");
                                                        } else {
                                                            out.print(shortDesc != null ? shortDesc : "N/A");
                                                        }
                                                    %>
                                                </td>
                                                <td>RM <%= String.format("%.2f", treatment.getBaseConsultationCharge())%></td>
                                                <td>RM <%= String.format("%.2f", treatment.getFollowUpCharge())%></td>
                                                <td>
                                                    <%
                                                        int prescriptionCount = treatment.getPrescriptions() != null ? treatment.getPrescriptions().size() : 0;
                                                    %>
                                                    <span class="badge badge-info"><%= prescriptionCount%> prescriptions</span>
                                                </td>
                                                <td>
                                                    <div class="action-buttons">

                                                        <a href="<%= request.getContextPath()%>/TreatmentServlet?action=viewDetail&id=<%= treatment.getId()%>" 
                                                           class="btn btn-sm btn-info" title="View Details">
                                                            <i class="fa fa-eye"></i>
                                                        </a>
                                                        <a href="<%= request.getContextPath()%>/TreatmentServlet?action=editForm&id=<%= treatment.getId()%>" 
                                                           class="btn btn-sm btn-warning" title="Edit">
                                                            <i class="fa fa-edit"></i>
                                                        </a>
                                                        <a href="#" onclick="confirmDelete(<%= treatment.getId()%>, '<%= treatment.getName()%>')" 
                                                           class="btn btn-sm btn-danger" title="Delete">
                                                            <i class="fa fa-trash"></i>
                                                        </a>
                                                    </div>
                                                </td>
                                            </tr>
                                            <% } %>
                                        </tbody>
                                    </table>
                                    <% } else {%>


                                    <div class="no-data">
                                        <i class="fa fa-stethoscope"></i>
                                        <h4>No Treatment Found</h4>
                                        <p>No treatment match your search criteria.</p>
                                        <a href="<%= request.getContextPath()%>/TreatmentServlet?action=createForm" class="add-customer-btn">
                                            <i class="fa fa-plus"></i> Add Treatment
                                        </a>
                                    </div>

                                    <% }%>
                           
                    </div>
                </div>
        </section>

        <!-- Delete Confirmation Modal -->
        <div class="modal fade" id="deleteModal" tabindex="-1" role="dialog">
            <div class="modal-dialog" role="document">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">Confirm Delete</h5>
                        <button type="button" class="close" data-dismiss="modal">&times;</button>
                    </div>
                    <div class="modal-body">
                        <p>Are you sure you want to delete the treatment "<span id="treatmentName"></span>"?</p>
                        <p class="text-danger"><strong>Warning:</strong> This will also delete all associated prescriptions!</p>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
                        <form id="deleteForm" method="post" style="display: inline;">
                            <input type="hidden" name="action" value="delete">
                            <input type="hidden" name="id" id="deleteId">
                            <button type="submit" class="btn btn-danger">Delete</button>
                        </form>
                    </div>
                </div>
            </div>
        </div>

        <!-- Include footer -->
        <%@ include file="../includes/footer.jsp" %>

        <!-- Scripts -->
        <%@ include file="../includes/scripts.jsp" %>

        <script>
            function confirmDelete(id, name) {
                document.getElementById('deleteId').value = id;
                document.getElementById('treatmentName').textContent = name;
                document.getElementById('deleteForm').action = '<%= request.getContextPath()%>/TreatmentServlet';
                $('#deleteModal').modal('show');
            }

            // Auto-hide alerts after 5 seconds
            setTimeout(function () {
                $('.alert').fadeOut('slow');
            }, 5000);
        </script>
    </body>
</html>

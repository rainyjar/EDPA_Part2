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
    java.util.Map<Integer, Integer> prescriptionCounts = (java.util.Map<Integer, Integer>) request.getAttribute("prescriptionCounts");

%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Manage Treatments - AMC Healthcare System</title>

        <%@ include file="/includes/head.jsp" %>
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manager-homepage.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/manage-staff.css">

        <style>
            @media (max-width: 768px) {
                .search-form .form-row {
                    flex-direction: column;
                }

                .search-form .form-group {
                    width: 100%;
                    min-width: unset;
                }
            }
        </style>

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
                <div class="search-filter-section wow fadeInUp" data-wow-delay="0.2s">
                    <h3><i class="fa fa-search"></i> Search & Filter Treatments</h3>

                    <form method="GET" action="<%= request.getContextPath()%>/TreatmentServlet" class="search-form">
                        <input type="hidden" name="action" value="manage">

                        <div class="form-row">
                            <div class="form-group">
                                <label for="treatmentSearch">Search by Treatment Name/Description</label>
                                <input type="text" class="form-control" id="treatmentSearch" name="treatmentSearch" 
                                       placeholder="Enter treatment name or description..." onkeyup="filterTreatments()">
                            </div>

                            <div class="form-group">
                                <label for="prescriptionSearch">Search by Prescription (Condition/Medicine)</label>
                                <input type="text" class="form-control" id="prescriptionSearch" name="prescriptionSearch" 
                                       placeholder="Enter condition or medicine name..." onkeyup="filterTreatments()">
                            </div>

                            <div class="form-group">
                                <label for="chargeFilter">Filter by Charge Range</label>
                                <select class="form-control" id="chargeFilter" name="chargeFilter" onchange="filterTreatments()">
                                    <option value="all">All Charges</option>
                                    <option value="low">Low (RM 0 - 50)</option>
                                    <option value="medium">Medium (RM 51 - 100)</option>
                                    <option value="high">High (RM 101 - 200)</option>
                                    <option value="premium">Premium (RM 200+)</option>
                                </select>
                            </div>

                            <div class="form-group">
                                <label for="prescriptionCount">Filter by Prescription Count</label>
                                <select class="form-control" id="prescriptionCount" name="prescriptionCount" onchange="filterTreatments()">
                                    <option value="all">All Counts</option>
                                    <option value="none">No Prescriptions (0)</option>
                                    <option value="few">Few (1-2)</option>
                                    <option value="moderate">Moderate (3-5)</option>
                                    <option value="many">Many (6+)</option>
                                </select>
                            </div>

                        </div>
                        <div id="resultsInfo" class="text-muted small" style="margin-top: 5px;">
                            Showing all treatments
                        </div>

                        <div class="form-group">
                            <button type="button" class="btn btn-secondary" onclick="clearFilters()">
                                <i class="fa fa-refresh"></i> Clear Filters
                            </button>
                        </div>

                    </form>
                </div>


                <!-- TREATMENT MANAGEMENT SECTION -->
                <div class="staff-management-section wow fadeInUp" data-wow-delay="0.4s">
                    <div class="d-flex justify-content-between align-items-center mb-4">
                        <div>
                            <h3><i class="fa fa-list"></i> Treatment Directory</h3>
                        </div>
                        <div>
                            <a href="<%= request.getContextPath()%>/TreatmentServlet?action=createForm" class="add-customer-btn">
                                <i class="fa fa-plus"></i> Add Treatment
                            </a>
                        </div>
                    </div>

                    <!-- Treatments Table -->
                    <div class="staff-table">
                        <%  if (treatmentList != null && !treatmentList.isEmpty()) { %>

                        <table class="table table-hover" id="treatmentsTable">
                            <thead >
                                <tr>
                                    <th class="sortable" onclick="sortTable('treatmentsTable', 0, 'number')">
                                        ID <i class="fa fa-sort"></i>
                                    </th>
                                    <th class="sortable" onclick="sortTable('treatmentsTable', 1, 'string')">
                                        Treatment Name <i class="fa fa-sort"></i>
                                    </th>
                                    <th class="sortable" onclick="sortTable('treatmentsTable', 2, 'string')">
                                        Short Description <i class="fa fa-sort"></i>
                                    </th>
                                    <th class="sortable" onclick="sortTable('treatmentsTable', 3, 'number')">
                                        Base Charge (RM) <i class="fa fa-sort"></i>
                                    </th>
                                    <th class="sortable" onclick="sortTable('treatmentsTable', 4, 'number')">
                                        Follow-up Charge (RM) <i class="fa fa-sort"></i>
                                    </th>
                                    <th class="sortable" onclick="sortTable('treatmentsTable', 5, 'number')">
                                        Prescriptions <i class="fa fa-sort"></i>
                                    </th>
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
                                            int prescriptionCount = (prescriptionCounts != null && prescriptionCounts.get(treatment.getId()) != null) 
                                                ? prescriptionCounts.get(treatment.getId()) : 0;
                                        %>
                                        <span class="badge badge-info"><%= prescriptionCount%> prescriptions</span>
                                    </td>
                                    <td>
                                        <div class="action-buttons">

                                            <a href="<%= request.getContextPath()%>/TreatmentServlet?action=viewDetail&id=<%= treatment.getId()%>" 
                                               class="btn btn-sm btn-view" title="View Details">
                                                <i class="fa fa-eye"></i>
                                            </a>
                                            <a href="<%= request.getContextPath()%>/TreatmentServlet?action=editForm&id=<%= treatment.getId()%>" 
                                               class="btn btn-sm btn-edit" title="Edit">
                                                <i class="fa fa-edit"></i>
                                            </a>
                                            <a href="#" onclick="confirmDelete(<%= treatment.getId()%>, '<%= treatment.getName()%>')" 
                                               class="btn btn-sm btn-delete" title="Delete">
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

            // Search and Filter Functions
            function filterTreatments() {
                const treatmentSearch = document.getElementById('treatmentSearch').value.toLowerCase();
                const prescriptionSearch = document.getElementById('prescriptionSearch').value.toLowerCase();
                const chargeFilter = document.getElementById('chargeFilter').value;
                const prescriptionCountFilter = document.getElementById('prescriptionCount').value;

                const table = document.getElementById('treatmentsTable');
                const tbody = table.querySelector('tbody');
                const rows = tbody.querySelectorAll('tr');

                let visibleCount = 0;

                rows.forEach(row => {
                    const cells = row.querySelectorAll('td');
                    if (cells.length === 0)
                        return; // Skip empty rows

                    // Get cell values
                    const treatmentName = cells[1].textContent.toLowerCase();
                    const description = cells[2].textContent.toLowerCase();
                    const baseCharge = parseFloat(cells[3].textContent.replace(/[^\d.-]/g, ''));
                    const followUpCharge = parseFloat(cells[4].textContent.replace(/[^\d.-]/g, ''));
                    const prescriptionCountText = cells[5].textContent;
                    const prescriptionCount = parseInt(prescriptionCountText.match(/\d+/) ? prescriptionCountText.match(/\d+/)[0] : 0);

                    let showRow = true;

                    // Treatment name/description search
                    if (treatmentSearch && !treatmentName.includes(treatmentSearch) && !description.includes(treatmentSearch)) {
                        showRow = false;
                    }

                    // Prescription search (you may need to enhance this to search actual prescriptions)
                    if (prescriptionSearch && showRow) {
                        // For now, search in treatment name and description
                        // In a real implementation, you'd search the actual prescription data
                        if (!treatmentName.includes(prescriptionSearch) && !description.includes(prescriptionSearch)) {
                            showRow = false;
                        }
                    }

                    // Charge filter
                    if (chargeFilter !== 'all' && showRow) {
                        const maxCharge = Math.max(baseCharge, followUpCharge);
                        switch (chargeFilter) {
                            case 'low':
                                if (maxCharge > 50)
                                    showRow = false;
                                break;
                            case 'medium':
                                if (maxCharge <= 50 || maxCharge > 100)
                                    showRow = false;
                                break;
                            case 'high':
                                if (maxCharge <= 100 || maxCharge > 200)
                                    showRow = false;
                                break;
                            case 'premium':
                                if (maxCharge <= 200)
                                    showRow = false;
                                break;
                        }
                    }

                    // Prescription count filter
                    if (prescriptionCountFilter !== 'all' && showRow) {
                        switch (prescriptionCountFilter) {
                            case 'none':
                                if (prescriptionCount !== 0)
                                    showRow = false;
                                break;
                            case 'few':
                                if (prescriptionCount < 1 || prescriptionCount > 2)
                                    showRow = false;
                                break;
                            case 'moderate':
                                if (prescriptionCount < 3 || prescriptionCount > 5)
                                    showRow = false;
                                break;
                            case 'many':
                                if (prescriptionCount < 6)
                                    showRow = false;
                                break;
                        }
                    }

                    // Show/hide row
                    row.style.display = showRow ? '' : 'none';
                    if (showRow)
                        visibleCount++;
                });

                // Update results info or show no results message
                updateResultsInfo(visibleCount, rows.length);
            }

            function clearFilters() {
                document.getElementById('treatmentSearch').value = '';
                document.getElementById('prescriptionSearch').value = '';
                document.getElementById('chargeFilter').value = 'all';
                document.getElementById('prescriptionCount').value = 'all';
                filterTreatments();
            }

            function updateResultsInfo(visible, total) {
                const resultsInfo = document.getElementById('resultsInfo');
                if (resultsInfo) {
                    if (visible === total) {
                        resultsInfo.textContent = 'Showing all ' + total + ' treatments';
                    } else {
                        resultsInfo.textContent = 'Showing ' + visible + ' of ' + total + ' treatments';
                    }
                    resultsInfo.style.color = visible === 0 ? '#dc3545' : '#6c757d';
                }
            }

            // Table Sorting Function (adapted from customer management)
            let sortDirections = {}; // Track sort direction for each table and column

            function sortTable(tableId, columnIndex, dataType) {
                const table = document.getElementById(tableId);
                const tbody = table.querySelector('tbody');
                const rows = Array.from(tbody.querySelectorAll('tr')).filter(row => row.style.display !== 'none');

                // Determine sort direction
                const sortKey = tableId + '_' + columnIndex;
                const currentDirection = sortDirections[sortKey] || 'asc';
                const newDirection = currentDirection === 'asc' ? 'desc' : 'asc';
                sortDirections[sortKey] = newDirection;

                // Update sort icons
                updateSortIcons(tableId, columnIndex, newDirection);

                // Sort rows
                rows.sort((a, b) => {
                    let valueA = a.cells[columnIndex].textContent.trim();
                    let valueB = b.cells[columnIndex].textContent.trim();

                    // Handle different data types
                    if (dataType === 'number') {
                        // Extract numeric values
                        valueA = parseFloat(valueA.replace(/[^\d.-]/g, '')) || 0;
                        valueB = parseFloat(valueB.replace(/[^\d.-]/g, '')) || 0;

                        if (newDirection === 'asc') {
                            return valueA - valueB;
                        } else {
                            return valueB - valueA;
                        }
                    } else {
                        // String comparison (case-insensitive)
                        valueA = valueA.toLowerCase();
                        valueB = valueB.toLowerCase();

                        if (newDirection === 'asc') {
                            return valueA.localeCompare(valueB);
                        } else {
                            return valueB.localeCompare(valueA);
                        }
                    }
                });

                // Re-append sorted rows
                rows.forEach(row => tbody.appendChild(row));

                // Add visual feedback
                animateTableSort(tableId);
            }

            function updateSortIcons(tableId, activeColumn, direction) {
                const table = document.getElementById(tableId);
                const headers = table.querySelectorAll('th.sortable');

                headers.forEach((header, index) => {
                    const icon = header.querySelector('i');
                    if (index === activeColumn) {
                        // Active column
                        icon.className = direction === 'asc' ? 'fa fa-sort-up' : 'fa fa-sort-down';
                    } else {
                        // Inactive columns
                        icon.className = 'fa fa-sort';
                    }
                });
            }

            function animateTableSort(tableId) {
                const table = document.getElementById(tableId);
                table.style.opacity = '0.7';
                setTimeout(() => {
                    table.style.opacity = '1';
                }, 200);
            }

            // Initialize on page load
            $(document).ready(function () {
                // Initialize tooltips if needed
                $('[data-toggle="tooltip"]').tooltip();

                // Set up real-time search
                document.getElementById('treatmentSearch').addEventListener('input', filterTreatments);
                document.getElementById('prescriptionSearch').addEventListener('input', filterTreatments);

                // Initialize results info
                const table = document.getElementById('treatmentsTable');
                if (table) {
                    const tbody = table.querySelector('tbody');
                    const totalRows = tbody.querySelectorAll('tr').length;
                    updateResultsInfo(totalRows, totalRows);
                }
            });
        </script>
    </body>
</html>

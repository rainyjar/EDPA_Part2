<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.Collections" %>
<%@ page import="java.util.Comparator" %>
<%@ page import="model.*" %>
<%@ page import="java.text.DecimalFormat" %>

<%
    // Get data from servlet attributes (similar to ManagerServlet pattern)
    List<Doctor> doctorList = (List<Doctor>) request.getAttribute("doctorList");
    List<CounterStaff> staffList = (List<CounterStaff>) request.getAttribute("staffList");
    List<Feedback> feedbackList = (List<Feedback>) request.getAttribute("feedbackList");

    // Get search/filter parameters
    String searchQuery = request.getParameter("search");
    String ratingFilter = request.getParameter("rating");
    String genderFilter = request.getParameter("gender");

    if (searchQuery == null) {
        searchQuery = "";
    }
    if (ratingFilter == null) {
        ratingFilter = "all";
    }
    if (genderFilter == null) {
        genderFilter = "all";
    }

    // Initialize decimal formatter
    DecimalFormat df = new DecimalFormat("#.#");

    // Calculate feedback counts for all staff (based on feedback table)
    Map<Integer, Integer> doctorFeedbackCounts = new HashMap<Integer, Integer>();
    Map<Integer, Integer> staffFeedbackCounts = new HashMap<Integer, Integer>();

    // Calculate doctor feedback counts
    if (doctorList != null && feedbackList != null) {
        for (Doctor doctor : doctorList) {
            int feedbackCount = 0;

            for (Feedback feedback : feedbackList) {
                if (feedback.getToDoctor() != null && feedback.getToDoctor().getId() == doctor.getId()) {
                    // Count all feedbacks for this doctor (rating can be 0.0 for valid feedback)
                    feedbackCount++;
                }
            }

            doctorFeedbackCounts.put(doctor.getId(), feedbackCount);
        }
    }

    // Calculate counter staff feedback counts
    if (staffList != null && feedbackList != null) {
        for (CounterStaff staff : staffList) {
            int feedbackCount = 0;

            for (Feedback feedback : feedbackList) {
                if (feedback.getToStaff() != null && feedback.getToStaff().getId() == staff.getId()) {
                    // Count all feedbacks for this staff (rating can be 0.0 for valid feedback)
                    feedbackCount++;
                }
            }

            staffFeedbackCounts.put(staff.getId(), feedbackCount);
        }
    }

    // Filter and sort doctors based on search criteria (similar to ManagerServlet pattern)
    List<Doctor> filteredDoctors = new ArrayList<Doctor>();
    if (doctorList != null) {
        for (Doctor doctor : doctorList) {
            boolean matchesSearch = searchQuery.isEmpty()
                    || doctor.getName().toLowerCase().contains(searchQuery.toLowerCase())
                    || doctor.getEmail().toLowerCase().contains(searchQuery.toLowerCase());

            boolean matchesGender = "all".equals(genderFilter)
                    || genderFilter.equals(doctor.getGender());

            // Rating-based filtering
            boolean matchesRating = true;
            if (ratingFilter != null && !ratingFilter.isEmpty() && !ratingFilter.equals("all")) {
                Double rating = doctor.getRating();
                if ("9-10".equals(ratingFilter)) {
                    matchesRating = rating != null && rating >= 9.0 && rating <= 10.0;
                } else if ("7-8".equals(ratingFilter)) {
                    matchesRating = rating != null && rating >= 7.0 && rating < 9.0;
                } else if ("4-6".equals(ratingFilter)) {
                    matchesRating = rating != null && rating >= 4.0 && rating < 7.0;
                } else if ("1-3".equals(ratingFilter)) {
                    matchesRating = rating != null && rating >= 1.0 && rating < 4.0;
                } else if ("no-rating".equals(ratingFilter)) {
                    matchesRating = rating == null || rating == 0.0;
                }
            }

            if (matchesSearch && matchesGender && matchesRating) {
                filteredDoctors.add(doctor);
            }
        }

        // Sort by ID (ascending) - default sort when page loads
        Collections.sort(filteredDoctors, new Comparator<Doctor>() {
            public int compare(Doctor d1, Doctor d2) {
                return Integer.compare(d1.getId(), d2.getId());
            }
        });
    }

    // Filter and sort counter staff
    List<CounterStaff> filteredCounterStaff = new ArrayList<CounterStaff>();
    if (staffList != null) {
        for (CounterStaff staff : staffList) {
            boolean matchesSearch = searchQuery.isEmpty()
                    || staff.getName().toLowerCase().contains(searchQuery.toLowerCase())
                    || staff.getEmail().toLowerCase().contains(searchQuery.toLowerCase());

            boolean matchesGender = "all".equals(genderFilter)
                    || genderFilter.equals(staff.getGender());

            // Rating-based filtering
            boolean matchesRating = true;
            if (ratingFilter != null && !ratingFilter.isEmpty() && !ratingFilter.equals("all")) {
                Double rating = staff.getRating();
                if ("9-10".equals(ratingFilter)) {
                    matchesRating = rating != null && rating >= 9.0 && rating <= 10.0;
                } else if ("7-8".equals(ratingFilter)) {
                    matchesRating = rating != null && rating >= 7.0 && rating < 9.0;
                } else if ("4-6".equals(ratingFilter)) {
                    matchesRating = rating != null && rating >= 4.0 && rating < 7.0;
                } else if ("1-3".equals(ratingFilter)) {
                    matchesRating = rating != null && rating >= 1.0 && rating < 4.0;
                } else if ("no-rating".equals(ratingFilter)) {
                    matchesRating = rating == null || rating == 0.0;
                }
            }

            if (matchesSearch && matchesGender && matchesRating) {
                filteredCounterStaff.add(staff);
            }
        }

        // Sort by ID (ascending) - default sort when page loads
        Collections.sort(filteredCounterStaff, new Comparator<CounterStaff>() {
            public int compare(CounterStaff s1, CounterStaff s2) {
                return Integer.compare(s1.getId(), s2.getId());
            }
        });
    }

    // Create top-rated staff list (JSP handles this logic)
    List<Map<String, Object>> topRatedStaff = new ArrayList<Map<String, Object>>();

    // Add doctors to top-rated list
    if (doctorList != null) {
        for (Doctor doctor : doctorList) {
            Double rating = doctor.getRating();
            Integer feedbackCount = doctorFeedbackCounts.get(doctor.getId());

            if (rating != null && rating > 0) {
                Map<String, Object> staffData = new HashMap<String, Object>();
                staffData.put("id", doctor.getId());
                staffData.put("name", "Dr. " + doctor.getName());
                staffData.put("role", "Doctor");
                staffData.put("type", "doctor");
                staffData.put("department", doctor.getSpecialization() != null ? doctor.getSpecialization() : "General");
                staffData.put("rating", rating);
                staffData.put("feedbackCount", feedbackCount != null ? feedbackCount : 0);
                topRatedStaff.add(staffData);
            }
        }
    }

    // Add counter staff to top-rated list
    if (staffList != null) {
        for (CounterStaff staff : staffList) {
            Double rating = staff.getRating();
            Integer feedbackCount = staffFeedbackCounts.get(staff.getId());

            if (rating != null && rating > 0) {
                Map<String, Object> staffData = new HashMap<String, Object>();
                staffData.put("id", staff.getId());
                staffData.put("name", staff.getName());
                staffData.put("role", "Counter Staff");
                staffData.put("type", "staff");
                staffData.put("department", "Administration");
                staffData.put("rating", rating);
                staffData.put("feedbackCount", feedbackCount != null ? feedbackCount : 0);
                topRatedStaff.add(staffData);
            }
        }
    }

    // Sort top-rated staff and take top 5
    Collections.sort(topRatedStaff, new Comparator<Map<String, Object>>() {
        public int compare(Map<String, Object> s1, Map<String, Object> s2) {
            Double rating1 = (Double) s1.get("rating");
            Double rating2 = (Double) s2.get("rating");
            return rating2.compareTo(rating1);
        }
    });

    // Get top 5
    List<Map<String, Object>> top5Staff = topRatedStaff.subList(0, Math.min(5, topRatedStaff.size()));
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <title>Staff Rating - APU Medical Center</title>
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
                            <i class="fa fa-star" style="color:white"></i>
                            <span style="color:white">Staff Ratings</span>
                        </h1>
                        <p class="lead wow fadeInUp" data-wow-delay="0.2s" style="color: whitesmoke">
                            View and analyze staff performance ratings from customer feedback
                        </p>
                        <nav aria-label="breadcrumb" class="wow fadeInUp" data-wow-delay="0.3s">
                            <ol class="breadcrumb"  style="background: transparent; margin: 0;">
                                <li class="breadcrumb-item"><a href="<%= request.getContextPath()%>/manager/manager_homepage.jsp" style="color: rgba(255,255,255,0.8);">Dashboard</a></li>
                                <li class="breadcrumb-item active" style="color: white;">Staff Rating</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>
        </section>

        <!-- MAIN CONTENT -->
        <section style="padding: 40px 0; background: #f5f5f5;">
            <div class="container">
                <!-- SEARCH AND FILTER SECTION -->
                <div class="search-filter-section wow fadeInUp" data-wow-delay="0.2s">
                    <h3><i class="fa fa-search"></i> Search & Filter Staff</h3>

                    <form method="GET" action="<%= request.getContextPath()%>/StaffRatingServlet" class="search-form">
                        <div class="form-row">
                            <div class="form-group col-md-4">
                                <label for="search"><strong>Search Staff:</strong></label>
                                <input type="text" id="search" name="search" class="form-control" 
                                       placeholder="Search by name or email..." value="<%= searchQuery%>">
                            </div>
                            <div class="form-group col-md-3">
                                <label for="rating"><strong>Filter by Rating:</strong></label>
                                <select id="rating" name="rating" class="form-control">
                                    <option value="all" <%= "all".equals(ratingFilter) ? "selected" : ""%>>All Ratings</option>
                                    <option value="9-10" <%= "9-10".equals(ratingFilter) ? "selected" : ""%>>Excellent (9-10)</option>
                                    <option value="7-8" <%= "7-8".equals(ratingFilter) ? "selected" : ""%>>Good (7-8)</option>
                                    <option value="4-6" <%= "4-6".equals(ratingFilter) ? "selected" : ""%>>Average (4-6)</option>
                                    <option value="1-3" <%= "1-3".equals(ratingFilter) ? "selected" : ""%>>Poor (1-3)</option>
                                    <option value="no-rating" <%= "no-rating".equals(ratingFilter) ? "selected" : ""%>>No Rating</option>
                                </select>
                            </div>
                            <div class="form-group col-md-3">
                                <label for="gender"><strong>Filter by Gender:</strong></label>
                                <select id="gender" name="gender" class="form-control">
                                    <option value="all" <%= "all".equals(genderFilter) ? "selected" : ""%>>All Genders</option>
                                    <option value="Male" <%= "Male".equals(genderFilter) ? "selected" : ""%>>Male</option>
                                    <option value="Female" <%= "Female".equals(genderFilter) ? "selected" : ""%>>Female</option>
                                </select>
                            </div>
                            <div class="form-group col-md-2">
                                <label>&nbsp;</label>
                                <div class="d-flex">
                                    <button type="submit" class="btn btn-primary mr-2">
                                        <i class="fa fa-search"></i> Search
                                    </button>
                                    <button type="button" class="btn btn-secondary" onclick="resetFilters()" style="background: none;">
                                        <i class="fa fa-refresh"></i> Reset
                                    </button>
                                </div>
                            </div>
                        </div>
                    </form>
                </div>

                <!-- STAFF RATING SECTION -->
                <div class="staff-management-section wow fadeInUp" data-wow-delay="0.4s">
                    <h3><i class="fa fa-star"></i> Staff Rating & Performance</h3>

                    <!-- Tab Navigation -->
                    <div class="tab-buttons">
                        <button class="tab-btn active" onclick="showTab('doctors')">
                            <i class="fa fa-user-md"></i> Doctors (<%= filteredDoctors.size()%>)
                        </button>
                        <button class="tab-btn" onclick="showTab('counter-staff')">
                            <i class="fa fa-users"></i> Counter Staff (<%= filteredCounterStaff.size()%>)
                        </button>
                        <button class="tab-btn" onclick="showTab('top-rated')">
                            <i class="fa fa-trophy"></i> Top 5 Rated (<%= top5Staff.size()%>)
                        </button>
                    </div>

                    <!-- Tab Contents -->
                    <div class="tab-contents">
                        <!-- Doctors Tab -->
                        <div id="doctors-tab" class="tab-content" style="display: block;">
                            <div class="staff-table">
                                <table class="table" id="doctorsTable">
                                    <thead>
                                        <tr>
                                            <th class="sortable" onclick="sortTable('doctorsTable', 0, 'number')">
                                                ID <i class="fa fa-sort"></i>
                                            </th>
                                            <th class="sortable" onclick="sortTable('doctorsTable', 1, 'text')">
                                                Name <i class="fa fa-sort"></i>
                                            </th>
                                            <th class="sortable" onclick="sortTable('doctorsTable', 2, 'text')">
                                                Specialization <i class="fa fa-sort"></i>
                                            </th>
                                            <th class="sortable" onclick="sortTable('doctorsTable', 3, 'number')">
                                                Rating  <i class="fa fa-sort"></i>
                                            </th>
                                            <th class="sortable" onclick="sortTable('doctorsTable', 4, 'number')">
                                                No of Feedback <i class="fa fa-sort"></i>
                                            </th>
                                            <th>Action</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <%
                                            if (filteredDoctors.isEmpty()) {
                                        %>
                                        <tr>
                                            <td colspan="6" class="text-center no-data">
                                                <i class="fa fa-exclamation-circle"></i><br>
                                                <% if (searchQuery.isEmpty() && "all".equals(ratingFilter) && "all".equals(genderFilter)) { %>
                                                Please use search or filters to view staff ratings.
                                                <% } else { %>
                                                No doctors found matching your criteria.
                                                <% } %>
                                            </td>
                                        </tr>
                                        <%
                                        } else {
                                            for (int i = 0; i < filteredDoctors.size(); i++) {
                                                Doctor doctor = filteredDoctors.get(i);
                                                int feedbackCount = doctorFeedbackCounts.get(doctor.getId());
                                        %>
                                        <tr>
                                            <td><%= doctor.getId()%></td>
                                            <td>Dr. <%= doctor.getName()%></td>
                                            <td><span class="badge badge-info">
                                                    <%= doctor.getSpecialization() != null ? doctor.getSpecialization() : "General"%>
                                                </span></td>
                                            <td>
                                                <%
                                                    Double doctorRating = doctor.getRating();
                                                    if (doctorRating != null && doctorRating > 0) {
                                                %> 
                                                <div class="rating-display">
                                                    <i class="fa fa-star rating-stars"></i><%= df.format(doctorRating)%>/10       
                                                </div>
                                                <%
                                                } else {
                                                %>
                                                <span class="text-muted">No Rating</span>
                                                <%
                                                    }
                                                %>
                                            </td>
                                            <td><%= feedbackCount%></td>
                                            <td>
                                                <button class="btn btn-sm btn-view" data-staff-type="doctor" data-staff-id="<%= doctor.getId()%>" data-staff-name="Dr. <%= doctor.getName()%>" onclick="viewStaffFeedback(this)">
                                                    <i class="fa fa-eye"></i>
                                                </button>
                                            </td>
                                        </tr>
                                        <%
                                                }
                                            }
                                        %>
                                    </tbody>
                                </table>
                            </div>
                        </div>

                        <!-- Counter Staff Tab -->
                        <div id="counter-staff-tab" class="tab-content" style="display: none;">
                            <div class="staff-table">
                                <table class="table" id="counterStaffTable">
                                    <thead>
                                        <tr>
                                            <th class="sortable" onclick="sortTable('counterStaffTable', 0, 'number')">
                                                ID <i class="fa fa-sort"></i>
                                            </th>
                                            <th class="sortable" onclick="sortTable('counterStaffTable', 1, 'text')">
                                                Name <i class="fa fa-sort"></i>
                                            </th>
                                            <th class="sortable" onclick="sortTable('counterStaffTable', 2, 'number')">
                                                Rating <i class="fa fa-sort"></i>
                                            </th>
                                            <th class="sortable" onclick="sortTable('counterStaffTable', 3, 'number')">
                                                No of Feedback <i class="fa fa-sort"></i>
                                            </th>
                                            <th>Action</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <%
                                            if (filteredCounterStaff.isEmpty()) {
                                        %>
                                        <tr>
                                            <td colspan="5" class="text-center no-data">
                                                <i class="fa fa-exclamation-circle"></i><br>
                                                <% if (searchQuery.isEmpty() && "all".equals(ratingFilter) && "all".equals(genderFilter)) { %>
                                                Please use search or filters to view staff ratings.
                                                <% } else { %>
                                                No counter staff found matching your criteria.
                                                <% } %>
                                            </td>
                                        </tr>
                                        <%
                                        } else {
                                            for (int i = 0; i < filteredCounterStaff.size(); i++) {
                                                CounterStaff staff = filteredCounterStaff.get(i);
                                                Double rating = staff.getRating();
                                                int feedbackCount = staffFeedbackCounts.get(staff.getId());
                                        %>
                                        <tr>
                                            <td><%= staff.getId()%></td>
                                            <td><%= staff.getName()%></td>
                                            <td>
                                                <%
                                                    if (rating != null && rating > 0) {
                                                %>
                                                <div class="rating-display">
                                                    <i class="fa fa-star rating-stars"></i><%= df.format(rating)%>/10
                                                </div>
                                                <%
                                                } else {
                                                %>
                                                <span class="text-muted">No Rating</span>
                                                <%
                                                    }
                                                %>
                                            </td>
                                            <td><%= feedbackCount%></td>
                                            <td>
                                                <button class="btn btn-sm btn-view" data-staff-type="staff" data-staff-id="<%= staff.getId()%>" data-staff-name="<%= staff.getName()%>" onclick="viewStaffFeedback(this)">
                                                    <i class="fa fa-eye"></i>
                                                </button>
                                            </td>
                                        </tr>
                                        <%
                                                }
                                            }
                                        %>
                                    </tbody>
                                </table>
                            </div>
                        </div>

                        <!-- Top 5 Rated Tab -->
                        <div id="top-rated-tab" class="tab-content" style="display: none;">
                            <div class="staff-table">
                                <table class="table" id="topRatedTable">
                                    <thead>
                                        <tr>
                                            <th class="sortable" onclick="sortTable('topRatedTable', 0, 'number')">
                                                Rank <i class="fa fa-sort"></i>
                                            </th>
                                            <th>Name</th>
                                            <th>Role</th>
                                            <th>Department/Specialization</th>
                                            <th>Rating</th>
                                            <th>No of Feedback</th>
                                            <th>Action</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <%
                                            if (top5Staff.isEmpty()) {
                                        %>
                                        <tr>
                                            <td colspan="7" class="text-center no-data">
                                                <i class="fa fa-trophy"></i><br>
                                                No rated staff found yet.
                                            </td>
                                        </tr>
                                        <%
                                        } else {
                                            for (int i = 0; i < top5Staff.size(); i++) {
                                                Map<String, Object> staffData = top5Staff.get(i);
                                                double rating = (Double) staffData.get("rating");
                                                int feedbackCount = (Integer) staffData.get("feedbackCount");
                                        %>
                                        <tr class="<%= i < 3 ? "top-performer" : ""%>">
                                            <td data-rank="<%= i + 1%>">
                                                <% if (i == 0) {%>
                                                <i class="fa fa-trophy" style="color: #FFD700;"></i> #1
                                                <% } else if (i == 1) {%>
                                                <i class="fa fa-trophy" style="color: #C0C0C0;"></i> #2
                                                <% } else if (i == 2) {%>
                                                <i class="fa fa-trophy" style="color: #CD7F32;"></i> #3
                                                <% } else {%>
                                                #<%= i + 1%>
                                                <% }%>
                                            </td>
                                            <td><%= staffData.get("name")%></td>
                                            <td><%= staffData.get("role")%></td>
                                            <td><span class="badge badge-info"><%= staffData.get("department")%></span></td>
                                            <td> <div class="rating-display">
                                                    <i class="fa fa-star rating-stars"></i><%= df.format(rating)%>/10
                                                </div>
                                            </td>
                                            <td><%= feedbackCount%></td>
                                            <td>
                                                <button class="btn btn-sm btn-view" data-staff-type="<%= staffData.get("type")%>" data-staff-id="<%= staffData.get("id")%>" data-staff-name="<%= staffData.get("name")%>" onclick="viewStaffFeedback(this)">
                                                    <i class="fa fa-eye"></i>
                                                </button>
                                            </td>
                                        </tr>
                                        <%
                                                }
                                            }
                                        %>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
        </section>

        <%@ include file="/includes/footer.jsp" %>
        <%@ include file="/includes/scripts.jsp" %>

        <script>
            // Tab switching functionality
            function showTab(tabName) {
                // Hide all tabs
                document.querySelectorAll('.tab-content').forEach(tab => {
                    tab.style.display = 'none';
                });

                // Remove active class from all buttons
                document.querySelectorAll('.tab-btn').forEach(btn => {
                    btn.classList.remove('active');
                });

                // Show selected tab
                document.getElementById(tabName + '-tab').style.display = 'block';

                // Add active class to clicked button
                event.target.classList.add('active');
            }

            // View staff feedback function
            function viewStaffFeedback(button) {
                const staffType = button.getAttribute('data-staff-type');
                const staffId = button.getAttribute('data-staff-id');
                const staffName = button.getAttribute('data-staff-name');

                const confirmMsg = 'View detailed feedback for ' + staffName + '?\n\n' +
                        'This will show all feedback received from customers including:\n' +
                        '- Customer names and dates\n' +
                        '- Treatment details\n' +
                        '- Rating scores and comments';

                if (confirm(confirmMsg)) {
                    window.open('<%= request.getContextPath()%>/StaffRatingServlet?action=viewFeedbackDetails&type=' + staffType + '&id=' + staffId + '&name=' + encodeURIComponent(staffName), '_blank', 'width=800,height=600,scrollbars=yes');
                }
            }

            // Reset all filters
            function resetFilters() {
                document.getElementById('search').value = '';
                document.getElementById('rating').value = 'all';
                document.getElementById('gender').value = 'all';

                // Submit the form to refresh the page with cleared filters
                document.querySelector('.search-form').submit();
            }

            // Table Sorting Function
            let sortDirections = {};

            function sortTable(tableId, columnIndex, dataType) {
                const table = document.getElementById(tableId);
                const tbody = table.querySelector('tbody');
                const rows = Array.from(tbody.querySelectorAll('tr'));

                if (rows.length === 0 || rows[0].querySelector('.no-data')) {
                    return;
                }

                const sortKey = tableId + '_' + columnIndex;
                const currentDirection = sortDirections[sortKey] || 'asc';
                const newDirection = currentDirection === 'asc' ? 'desc' : 'asc';
                sortDirections[sortKey] = newDirection;

                updateSortIcons(tableId, columnIndex, newDirection);

                rows.sort((a, b) => {
                    let aValue = a.cells[columnIndex].textContent.trim();
                    let bValue = b.cells[columnIndex].textContent.trim();

                    if (dataType === 'number') {
                        // Handle special cases for rating columns and rank columns
                        if (aValue.includes('No Rating'))
                            aValue = '0';
                        if (bValue.includes('No Rating'))
                            bValue = '0';

                        // For rank column, use data-rank attribute for accurate sorting
                        if (tableId === 'topRatedTable' && columnIndex === 0) {
                            aValue = a.cells[columnIndex].getAttribute('data-rank') || '0';
                            bValue = b.cells[columnIndex].getAttribute('data-rank') || '0';
                        }
                        // Extract numeric value from rating (e.g., "★8.5/10" -> 8.5)
                        else if (aValue.includes('/10')) {
                            aValue = aValue.replace(/[^\d.]/g, '').split('.')[0] + '.' + (aValue.replace(/[^\d.]/g, '').split('.')[1] || '0');
                        }
                        if (bValue.includes('/10')) {
                            bValue = bValue.replace(/[^\d.]/g, '').split('.')[0] + '.' + (bValue.replace(/[^\d.]/g, '').split('.')[1] || '0');
                        }

                        // Handle other rank values (e.g., "🏆 #1" -> 1) - fallback
                        if (aValue.includes('#') && !aValue.includes('/10')) {
                            aValue = aValue.replace(/[^0-9]/g, '');
                        }
                        if (bValue.includes('#') && !bValue.includes('/10')) {
                            bValue = bValue.replace(/[^0-9]/g, '');
                        }

                        aValue = parseFloat(aValue) || 0;
                        bValue = parseFloat(bValue) || 0;

                        if (newDirection === 'asc') {
                            return aValue - bValue;
                        } else {
                            return bValue - aValue;
                        }
                    } else {
                        return newDirection === 'asc'
                                ? aValue.localeCompare(bValue)
                                : bValue.localeCompare(aValue);
                    }
                });

                rows.forEach(row => tbody.appendChild(row));

                // Update row numbers for counter staff table (ID column shows sequential numbers)
                if (tableId === 'counterStaffTable' && columnIndex === 0) {
                    rows.forEach((row, index) => {
                        row.cells[0].textContent = index + 1;
                    });
                }

                animateTableSort(tableId);
            }

            function updateSortIcons(tableId, activeColumn, direction) {
                const table = document.getElementById(tableId);
                const headers = table.querySelectorAll('th.sortable');

                headers.forEach((header, index) => {
                    const icon = header.querySelector('i');
                    if (icon) {
                        if (index === activeColumn) {
                            icon.className = direction === 'asc' ? 'fa fa-sort-up' : 'fa fa-sort-down';
                        } else {
                            icon.className = 'fa fa-sort';
                        }
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

            // Auto-submit form on filter change
            $(document).ready(function () {
                $('[data-toggle="tooltip"]').tooltip();
                $('#rating, #gender').change(function () {
                    $(this).closest('form').submit();
                });
            });
        </script>
    </body>
</html>

<%-- 
    Document   : home
    Created on : Jul 19, 2025, 12:36:50 PM
    Author     : chris
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@ page import="javax.servlet.http.HttpSession" %>
<%
    String doctorName = (String) session.getAttribute("name");
    if (doctorName == null) {
        doctorName = "Doctor"; // fallback if session expired
    }
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>Doctor Dashboard</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
        <script>
            function openNav() {
                document.getElementById("sidebar").style.width = "250px";
            }
            function closeNav() {
                document.getElementById("sidebar").style.width = "0";
            }
            function toggleSidebar() {
                const sidebar = document.getElementById('sidebar');
                if (sidebar.style.width === '250px' || sidebar.style.width === '') {
                    sidebar.style.width = '0';
                } else {
                    sidebar.style.width = '250px';
                }
            }
        </script>
        <style>
            .sidenav {
                position: fixed;
                top: 0;
                left: 0;
                height: 100%;
                z-index: 1000;
            }
            .sidenav a {
                display: block;
                padding: 10px 15px;
                text-decoration: none;
                color: #333;
                transition: 0.3s;
            }
            .sidenav a:hover {
                background-color: bg-blue-100;
            }
            .dropdown-content {
                display: none;
                padding-left: 20px;
            }
            .dropdown:hover .dropdown-content {
                display: block;
            }
        </style>
    </head>
    <body class="bg-gray-100 font-sans">
        <!-- Header -->
        <header class="bg-white shadow-md py-4 px-6 flex justify-between items-center fixed w-full z-50">
            <button onclick="toggleSidebar()" class="text-2xl font-bold">&#9776;</button>
            <div class="text-xl font-bold text-blue-600">APUMedCenter</div>
            <div class="space-x-4">
                <button class="bg-gray-200 px-4 py-2 rounded">X</button>
                <button class="bg-gray-200 px-4 py-2 rounded">X</button>
                <button class="bg-gray-200 px-4 py-2 rounded">X</button>
            </div>
        </header>

        <div class="flex pt-20 min-h-screen">
            <!-- Sidebar -->
            <aside id="sidebar" class="sidenav bg-white shadow-md transition-all duration-300 w-64 overflow-x-hidden" style="width: 0;">
                <a href="javascript:void(0)" class="text-right block p-2 text-xl font-bold text-red-500" onclick="closeNav()">&times;</a>
                <div class="p-4 text-blue-700 font-bold text-xl border-b">
                    <p>Welcome, </p>
                    <p><%= doctorName %>!</p>
                    
                </div>
                <nav class="mt-4 px-4 space-y-2 text-gray-700">
                    <a href="#" onclick="closeNav()" class="block py-2 px-4 rounded hover:bg-blue-100">🏠 Dashboard</a>
                    <div class="dropdown">
                        <a href="#" class="block py-2 px-4 rounded hover:bg-blue-100">💼 Manage Staff</a>
                        <div class="dropdown-content">
                            <a href="manage_manager.jsp" class="block py-2 px-4 rounded hover:bg-blue-100"> 👨🏻‍💼 Manager</a>
                            <a href="manage_cs.jsp" class="block py-2 px-4 rounded hover:bg-blue-100"> 👩🏻‍💻 Counter Staff</a>
                            <a href="manage_doc.jsp" class="block py-2 px-4 rounded hover:bg-blue-100"> 👨🏻‍⚕️ Doctor</a>
                        </div>
                    </div>
                    <a href="#" class="block py-2 px-4 rounded hover:bg-blue-100">📋 Appointments</a>
                    <a href="#" class="block py-2 px-4 rounded hover:bg-blue-100">💬 Comments</a>
                    <a href="#" class="block py-2 px-4 rounded hover:bg-blue-100">⭐ Ratings</a>
                    <a href="#" class="block py-2 px-4 rounded hover:bg-blue-100">📊 Reports</a>
                    <a href="#" class="block py-2 px-4 rounded hover:bg-blue-100">📨 Contact Staff</a>
                    <a href="#" class="block py-2 px-4 rounded hover:bg-red-100 text-red-600">🔓 Logout</a>
                </nav>
            </aside>

            <!-- Main Content -->
            <main class="flex-1 p-8">
                <!-- Top Cards -->
                <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-6">
                    <div class="bg-white shadow rounded p-4 text-center">
                        <h3 class="text-gray-500">Patients</h3>
                        <p class="text-2xl font-bold text-blue-600">1,280</p>
                    </div>
                    <div class="bg-white shadow rounded p-4 text-center">
                        <h3 class="text-gray-500">Doctors</h3>
                        <p class="text-2xl font-bold text-blue-600">65</p>
                    </div>
                    <div class="bg-white shadow rounded p-4 text-center">
                        <h3 class="text-gray-500">Appointments Today</h3>
                        <p class="text-2xl font-bold text-blue-600">34</p>
                    </div>
                    <div class="bg-white shadow rounded p-4 text-center">
                        <h3 class="text-gray-500">Monthly Revenue</h3>
                        <p class="text-2xl font-bold text-blue-600">RM25,200</p>
                    </div>
                </div>

                <!-- Charts + Quick Actions -->
                <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <div class="md:col-span-2 bg-white p-6 rounded shadow">
                        <h3 class="text-lg font-semibold mb-4">Monthly Appointments</h3>
                        <canvas id="appointmentsChart" height="120"></canvas>
                    </div>
                    <div class="bg-white p-6 rounded shadow space-y-4">
                        <h3 class="text-lg font-semibold mb-2">Quick Actions</h3>
                        <button class="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700">Manage Staff</button>
                        <button class="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700">View Appointments</button>
                        <button class="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700">Access Reports</button>
                        <button class="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700">Contact Doctors/CS</button>
                    </div>
                </div>
            </main>
        </div>

        <script>
            const ctx = document.getElementById('appointmentsChart').getContext('2d');
            new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
                    datasets: [{
                            label: 'Appointments',
                            data: [120, 150, 170, 180, 210, 250],
                            backgroundColor: '#3B82F6'
                        }]
                },
                options: {
                    responsive: true,
                    scales: {
                        y: {beginAtZero: true}
                    }
                }
            });
        </script>
    </body>
</html>

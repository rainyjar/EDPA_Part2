<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>

<html>
    <head>
        <title>All Appointments</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                margin: 30px;
                background-color: #f7f9fc;
            }
            h2 {
                text-align: center;
                color: #333;
            }
            table {
                width: 100%;
                border-collapse: collapse;
                background-color: #fff;
            }
            th, td {
                border: 1px solid #ccc;
                padding: 10px 12px;
                text-align: left;
            }
            th {
                background-color: #3366cc;
                color: white;
            }
            tr:nth-child(even) {
                background-color: #f0f4f8;
            }
        </style>
    </head>
    <body>
        <h2>All Appointments</h2>
        <table>
            <thead>
                <tr>
                    <th>Customer</th>
                    <th>Doctor</th>
                    <th>Treatment</th>
                    <th>Date</th>
                    <th>Time</th>
                    <th>Status</th>
                    <th>Customer Comment</th>
                    <th>Doctor Feedback</th>
                </tr>
            </thead>
            <tbody>
                <c:forEach var="apt" items="${appointments}">
                    <tr>
                        <td>${apt.customer.name}</td>
                        <td>${apt.doctor.name}</td>
                        <td>${apt.treatment.name}</td>
                        <td>${apt.appointmentDate}</td>
                        <td>${apt.appointmentTime}</td>
                        <td>${apt.status}</td>
                        <td>${apt.custMessage}</td>
                        <td>${apt.docMessage}</td>
                    </tr>
                </c:forEach>


            </tbody>
        </table>
    </body>
</html>

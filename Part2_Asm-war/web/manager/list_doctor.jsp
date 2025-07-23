<%@ page import="java.util.List" %>
<%@ page import="model.Doctor" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>


<html>
    <head>
        <title>Doctor List</title>
        <link rel="stylesheet" type="text/css" href="${pageContext.request.contextPath}/css/style.css">
    </head>
    <body>
        <h2>Doctor List</h2>

        <table border="1">
            <tr>
                <th>Name</th>
                <th>Email</th>
                <th>Phone</th>
                <th>Gender</th>
                <th>DOB</th>
                <th>Specialization</th>
                 <th>Profile Picture</th>
           
                <th>Actions</th>
            </tr>
            <c:forEach var="doctor" items="${doctorList}">
                <tr>
                    <td>${doctor.name}</td>
                    <td>${doctor.email}</td>
                    <td>${doctor.phone}</td>
                    <td>${doctor.gender}</td>
                    <td><fmt:formatDate value="${doctor.dob}" pattern="yyyy-MM-dd" /></td>
                    <td>${doctor.specialization}</td>
                    <td>${doctor.profilePic}</td>

                    <td>
                        <form method="get" action="${pageContext.request.contextPath}/DoctorServlet" style="display:inline;">
                            <input type="hidden" name="action" value="edit" />
                            <input type="hidden" name="id" value="${doctor.id}" />
                            <input type="submit" value="Edit" />
                        </form>

                        <form method="post" action="${pageContext.request.contextPath}/DoctorServlet" style="display:inline;" 
                              onsubmit="return confirm('Are you sure you want to delete this doctor?');">
                            <input type="hidden" name="action" value="delete" />
                            <input type="hidden" name="id" value="${doctor.id}" />
                            <input type="submit" value="Delete" />
                        </form>
                    </td>
                </tr>
            </c:forEach>
        </table>

    </body>
</html>

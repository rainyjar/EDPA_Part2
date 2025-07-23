<%@ page import="java.util.List" %>
<%@ page import="model.CounterStaff" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>


<html>
    <head>
        <title>Counter Staff List</title>
        <link rel="stylesheet" type="text/css" href="${pageContext.request.contextPath}/css/style.css">
    </head>
    <body>
        <h2>Counter Staff List</h2>

        <table border="1">
            <tr>
                <th>Name</th>
                <th>Email</th>
                <th>Phone</th>
                <th>Gender</th>
                <th>DOB</th>
                 <th>Profile Picture</th>
                <th>Actions</th>
            </tr>
            <c:forEach var="counter_staff" items="${counterStaffList}">
                <tr>
                    <td>${counter_staff.name}</td>
                    <td>${counter_staff.email}</td>
                    <td>${counter_staff.phone}</td>
                    <td>${counter_staff.gender}</td>
                    <td><fmt:formatDate value="${counter_staff.dob}" pattern="yyyy-MM-dd" /></td>
                     <td>${counter_staff.profilePic}</td>

                    <td>
                        <form method="get" action="${pageContext.request.contextPath}/CounterStaffServlet" style="display:inline;">
                            <input type="hidden" name="action" value="edit" />
                            <input type="hidden" name="id" value="${counter_staff.id}" />
                            <input type="submit" value="Edit" />
                        </form>

                        <form method="post" action="${pageContext.request.contextPath}/CounterStaffServlet" style="display:inline;" 
                              onsubmit="return confirm('Are you sure you want to delete this counter staff?');">
                            <input type="hidden" name="action" value="delete" />
                            <input type="hidden" name="id" value="${counter_staff.id}" />
                            <input type="submit" value="Delete" />
                        </form>
                    </td>
                </tr>
            </c:forEach>
        </table>

    </body>
</html>

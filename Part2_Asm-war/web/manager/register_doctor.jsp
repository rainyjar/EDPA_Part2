<%-- 
    Document   : doctorForm
    Created on : Jul 20, 2025, 6:52:29 PM
    Author     : chris
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Register Doctor</title>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css" />
    </head>
    <body>
        <div class="box">
            <h2>Register Doctor</h2>

            <!-- Error Message -->
            <% if (request.getAttribute("error") != null) {%>
            <div class="msg"><%= request.getAttribute("error")%></div>
            <% }%>

            <form method="post" enctype="multipart/form-data" action="${pageContext.request.contextPath}/DoctorServlet">
                <label>Name:</label>
                <input type="text" name="name" value="${doctor != null ? doctor.name : ''}" required /><br>

                <label>Email:</label>
                <input type="email" name="email" value="${doctor != null ? doctor.email : ''}" required /><br>

                <label>Password:</label>
                <input type="password" name="password" value="${doctor != null ? doctor.password : ''}" required /><br>

                <label>Phone:</label>
                <input type="text" name="phone" value="${doctor != null ? doctor.phone : ''}" required /><br>

                <label>Gender:</label>
                <select name="gender" required>
                    <option value="" disabled ${doctor == null ? "selected" : ""}>Choose Gender</option>
                    <option value="F" ${doctor != null && doctor.gender == 'F' ? "selected" : ""}>Female</option>
                    <option value="M" ${doctor != null && doctor.gender == 'M' ? "selected" : ""}>Male</option>
                </select><br>

                <label>Date of Birth:</label>
                <input type="date" name="dob" value="${doctor != null ? doctor.dob : ''}" required /><br>

                <label>Specialization: </label>
                <input type="text" name="specialization" value="${doctor != null ? doctor.specialization : ''}" required /><br>

                <!--// profile pic-->
                <label>Profile Picture: </label>
                <input type="file" name="profilePic" accept="image/*" required>

                <input class="login_btn" type="submit" value="Register" />

            </form>

        </form>
    </div>
</body>
</html>

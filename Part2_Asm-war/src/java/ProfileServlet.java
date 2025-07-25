/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Paths;
import java.util.logging.Logger;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;
import model.Customer;
import model.CustomerFacade;

/**
 *
 * @author chris
 */
@MultipartConfig
@WebServlet(urlPatterns = {"/ProfileServlet"})
public class ProfileServlet extends HttpServlet {

    @EJB
    private CustomerFacade customerFacade;
    private static final String UPLOAD_DIR = "images/profile_pictures";
    private static final Logger logger = Logger.getLogger(ProfileServlet.class.getName());

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);

        Customer customer = (Customer) session.getAttribute("customer");
        if (customer == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        request.getRequestDispatcher("customer/cust_profile.jsp").forward(request, response);
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");

        if ("updateProfile".equals(action)) {
            HttpSession session = request.getSession(false);
            Customer customer = (Customer) session.getAttribute("customer");
            // Retrieve form fields
            String name = request.getParameter("name");
            String email = request.getParameter("email");
            String phone = request.getParameter("phone");
            String dobStr = request.getParameter("dob");
            String gender = request.getParameter("gender");

            // valiadate required fields
            if (name == null || name.trim().isEmpty()
                    || email == null || email.trim().isEmpty()
                    || phone == null || phone.trim().isEmpty()
                    || dobStr == null || dobStr.trim().isEmpty()
                    || gender == null || gender.trim().isEmpty()) {

                // Handle validation error
                response.sendRedirect(request.getContextPath() + "/customer/cust_profile.jsp?error=missing_fields");
                return;
            }

            // Validate email format
            if (!email.matches("^[a-zA-Z0-9_+&*-]+(?:\\.[a-zA-Z0-9_+&*-]+)*@(?:[a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,7}$")) {
                response.sendRedirect(request.getContextPath() + "/customer/cust_profile.jsp?error=invalid_email");
                return;
            }

            // check if email already exists
            Customer existingCustomer = customerFacade.findByEmail(email);
            if (existingCustomer != null && existingCustomer.getId() != customer.getId()) {
                response.sendRedirect(request.getContextPath() + "/customer/cust_profile.jsp?error=email_taken");
                return;
            }

            // Convert dob string to java.sql.Date
            java.sql.Date dob = null;
            try {
                java.util.Date utilDate = new java.text.SimpleDateFormat("yyyy-MM-dd").parse(dobStr);
                dob = new java.sql.Date(utilDate.getTime());
            } catch (Exception e) {
                e.printStackTrace();
            }

            if (customer != null) {
                customer.setName(name);
                customer.setEmail(email);
                customer.setPhone(phone);
                customer.setGender(gender);
                customer.setDob(dob);

                customerFacade.edit(customer); // Make sure this is the EJB that updates the DB

                session.setAttribute("customer", customer); // Update session
                response.sendRedirect(request.getContextPath() + "/customer/cust_profile.jsp?success=profile_updated");
            } else {
                response.sendRedirect("login.jsp");
            }
        } else if ("updateProfilePic".equals(action)) {
            HttpSession session = request.getSession(true);
            Customer customer = (Customer) session.getAttribute("customer");

            if (customer != null) {
                try {
                    Part filePart = request.getPart("profilePic");
                    if (filePart != null && filePart.getSize() > 0) {
                        String fileName = null;
                        try {
                            fileName = UploadImage.uploadProfilePicture(filePart, request.getServletContext());
                            logger.info("File upload result: " + fileName);
                        } catch (Exception e) {
                            logger.severe("Exception during file upload: " + e.getMessage());
                            e.printStackTrace();
                            response.sendRedirect(
                                    request.getContextPath() + "/customer/cust_profile.jsp?error=upload_failed");
                            return;
                        }

                        // Save the relative path or filename in database (optional)
                        customer.setProfilePic(fileName);
                        customerFacade.edit(customer);

                        session.setAttribute("customer", customer); // Update session

                        Thread.sleep(3000);
                        response.sendRedirect(
                                request.getContextPath() + "/customer/cust_profile.jsp?success=picture_updated");
                    } else {
                        response.sendRedirect(request.getContextPath() + "/customer/cust_profile.jsp?error=no_file");
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    response.sendRedirect(request.getContextPath() + "/customer/cust_profile.jsp?error=upload_fail");
                }
            } else {
                response.sendRedirect("login.jsp");
            }
        } else if ("changePassword".equals(action)) {
            // change password logic
            HttpSession session = request.getSession(true);
            Customer customer = (Customer) session.getAttribute("customer");

            if (customer == null) {
                response.sendRedirect("login.jsp");
                return;
            }

            String currentPassword = request.getParameter("currentPassword");
            String newPassword = request.getParameter("newPassword");
            String confirmPassword = request.getParameter("confirmPassword");

            // validate required fields
            if (currentPassword == null || currentPassword.trim().isEmpty()
                    || newPassword == null || newPassword.trim().isEmpty()
                    || confirmPassword == null || confirmPassword.trim().isEmpty()) {

                response.sendRedirect(request.getContextPath() + "/customer/cust_profile.jsp?error=missing_fields");
                return;
            }

            // Verify current password
            if (!customer.getPassword().equals(currentPassword)) {
                response.sendRedirect(request.getContextPath() + "/customer/cust_profile.jsp?error=invalid_password");
                return;
            }

            // Check if new passwords match
            if (!newPassword.equals(confirmPassword)) {
                response.sendRedirect(request.getContextPath() + "/customer/cust_profile.jsp?error=password_mismatch");
                return;
            }

            // Validate password length (minimum 6 characters)
            if (newPassword.length() < 6) {
                response.sendRedirect(request.getContextPath() + "/customer/cust_profile.jsp?error=weak_password");
                return;
            }

            // Update password
            customer.setPassword(newPassword);
            customerFacade.edit(customer);

            session.setAttribute("customer", customer); // Update session
            // Redirect with success message
            response.sendRedirect(request.getContextPath() + "/customer/cust_profile.jsp?success=password_changed");
        }

    }

}

/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

import java.io.IOException;
import java.io.PrintWriter;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import model.Customer;
import model.CustomerFacade;

/**
 *
 * @author chris
 */
@WebServlet(urlPatterns = {"/Register"})
public class Register extends HttpServlet {

    @EJB
    private CustomerFacade customerFacade;

    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("text/html;charset=UTF-8");

        try (PrintWriter out = response.getWriter()) {
            String name = request.getParameter("name");
            String email = request.getParameter("email");
            String password = request.getParameter("password");

            // Empty fields validation
            if (name == null || email == null || password == null
                    || name.isEmpty() || email.isEmpty() || password.isEmpty()) {
                request.setAttribute("error", "All fields are required.");
                request.getRequestDispatcher("register.jsp").forward(request, response);
                return;
            }

            // Email validation
            if (!email.matches("^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$")) {
                request.setAttribute("error", "Invalid email format.");
                request.getRequestDispatcher("register.jsp").forward(request, response);
                return;
            }

            // Password validation
            if (password.length() < 6) {
                request.setAttribute("error", "Password must be at least 6 characters long.");
                request.getRequestDispatcher("register.jsp").forward(request, response);
                return;
            }

            try {
                // Check if customer email already exists
                Customer existingCustomer = customerFacade.searchEmail(email);
                if (existingCustomer != null) {
                    request.setAttribute("error", "Email already registered.");
                    request.getRequestDispatcher("register.jsp").forward(request, response);
                    return;
                }

                // Create new customer
                customerFacade.create(new Customer(name, email, password));
                request.setAttribute("success", "Registration successful! You can now login.");
                request.getRequestDispatcher("register.jsp").include(request, response);

            } catch (Exception e) {
                request.setAttribute("error", "Registration failed: " + e.getMessage());
                request.getRequestDispatcher("register.jsp").forward(request, response);
            }
        }

    }

    // <editor-fold defaultstate="collapsed" desc="HttpServlet methods. Click on the + sign on the left to edit the code.">
    /**
     * Handles the HTTP <code>GET</code> method.
     *
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /**
     * Handles the HTTP <code>POST</code> method.
     *
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /**
     * Returns a short description of the servlet.
     *
     * @return a String containing servlet description
     */
    @Override
    public String getServletInfo() {
        return "Short description";
    }// </editor-fold>

}

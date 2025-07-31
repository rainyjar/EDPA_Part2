/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package model;

import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

/**
 *
 * @author chris
 */
@Stateless
public class PaymentFacade extends AbstractFacade<Payment> {

    @PersistenceContext(unitName = "Part2_Asm-ejbPU")
    private EntityManager em;

    @Override
    protected EntityManager getEntityManager() {
        return em;
    }

    public PaymentFacade() {
        super(Payment.class);
    }

    /**
     * Find payment by appointment ID
     */
    public Payment findByAppointmentId(int appointmentId) {
        try {
            return em.createQuery("SELECT p FROM Payment p WHERE p.appointment.id = :appointmentId", Payment.class)
                    .setParameter("appointmentId", appointmentId)
                    .getSingleResult();
        } catch (Exception e) {
            return null;
        }
    }
    
    /**
     * Find payments by status
     */
    public java.util.List<Payment> findByStatus(String status) {
        try {
            return em.createQuery("SELECT p FROM Payment p WHERE p.status = :status ORDER BY p.paymentDate DESC", Payment.class)
                    .setParameter("status", status)
                    .getResultList();
        } catch (Exception e) {
            return new java.util.ArrayList<>();
        }
    }
    
    /**
     * Find all payments ordered by date
     */
    @Override
    public java.util.List<Payment> findAll() {
        try {
            return em.createQuery("SELECT p FROM Payment p ORDER BY p.paymentDate DESC", Payment.class)
                    .getResultList();
        } catch (Exception e) {
            return new java.util.ArrayList<>();
        }
    }

}

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
public class ReceiptFacade extends AbstractFacade<Receipt> {

    @PersistenceContext(unitName = "Part2_Asm-ejbPU")
    private EntityManager em;

    @Override
    protected EntityManager getEntityManager() {
        return em;
    }

    public ReceiptFacade() {
        super(Receipt.class);
    }

    /**
     * Find receipt by appointment ID
     */
    public Receipt findByAppointmentId(int appointmentId) {
        try {
            return em.createQuery("SELECT r FROM Receipt r WHERE r.appointment.id = :appointmentId", Receipt.class)
                    .setParameter("appointmentId", appointmentId)
                    .getSingleResult();
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Find receipt by payment ID
     */
    public Receipt findByPaymentId(int paymentId) {
        try {
            return em.createQuery("SELECT r FROM Receipt r WHERE r.payment.id = :paymentId", Receipt.class)
                    .setParameter("paymentId", paymentId)
                    .getSingleResult();
        } catch (Exception e) {
            return null;
        }
    }
}

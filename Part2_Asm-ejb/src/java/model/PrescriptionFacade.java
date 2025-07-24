/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package model;

import java.util.List;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

/**
 *
 * @author chris
 */
@Stateless
public class PrescriptionFacade extends AbstractFacade<Prescription> {

    @PersistenceContext(unitName = "Part2_Asm-ejbPU")
    private EntityManager em;

    @Override
    protected EntityManager getEntityManager() {
        return em;
    }

    public PrescriptionFacade() {
        super(Prescription.class);
    }

    public List<Prescription> findByTreatmentId(int treatmentId) {
        return em.createQuery("SELECT p FROM Prescription p WHERE p.treatment.id = :treatmentId", Prescription.class)
                .setParameter("treatmentId", treatmentId)
                .getResultList();
    }

}

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
import javax.persistence.Query;

/**
 *
 * @author chris
 */
@Stateless
public class CustomerFacade extends AbstractFacade<Customer> {

    @PersistenceContext(unitName = "Part2_Asm-ejbPU")
    private EntityManager em;

    @Override
    protected EntityManager getEntityManager() {
        return em;
    }

    public CustomerFacade() {
        super(Customer.class);
    }

    public Customer searchEmail(String email) {
        Query q = em.createNamedQuery("Customer.searchEmail");
        q.setParameter("x", email);
        List<Customer> result = q.getResultList();
        if (result.size() > 0) {
            return result.get(0);
        }
        return null;
    }

    /**
     * Find customer by email address
     *
     * @param email
     * @return Customer or null if not found
     */
    public Customer findByEmail(String email) {
        return searchEmail(email);
    }

    public void edit(Customer customer) {
        em.merge(customer);  // em is your EntityManager
    }

}

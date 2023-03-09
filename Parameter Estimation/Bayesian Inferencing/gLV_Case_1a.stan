// Stan file generating gLV Stan model
// Case 1a - For generating intra-interactivity parameters

// Function block:
functions {
  real[] logisticgrowth(real t,
                        real[] y,
                        real[] theta,
                        real[] x_r,
                        int[] x_i
  ) {
    
    real dudt = (1 - y[1]/Delta11 - y[2]/theta[1]) * y[1] * mu1 ;
    real dvdt =  (1 - y[2]/Delta22 - y[1]/theta[2]) * y[2] * mu2 ;
    
    return { dudt, dvdt };
  }
}

// The input data is a vector 'y' of length 'N'.
// Data block: Information conditioned upon. Lower = Lower bound.

data {
  int<lower=1> T;           // Number of total replicates
  int<lower=0> nReplicates; // Number of replicates to sample
  real y0[nReplicates];     // Initial Population size for replicates
  real z[T,nReplicates];    // Averaging across replicates?
  real t0;                  // Initial time
  real ts[T];               // Time step
}

// Transformed data
transformed data {
  real x_r[0];
  int x_i[1];
  x_i[1] = nReplicates;
}

// Accepted parameters to estimate (Interactivity terms [theta] and error est. [sigma])
parameters {
  real theta[2];
  real<lower=0> sigma;
}

// The model to be estimated. We model the output
// 'y' to be normally distributed with mean 'mu'
// and standard deviation 'sigma'.
model {
  real y_hat[T,nReplicates];
  theta[1] ~ cauchy(0,100000); // Vague choice of priors
  theta[2] ~ cauchy(0,100000); // Vague choice of priors
  sigma[1] ~ normal(0,1000000);
  sigma[2] ~ normal(0,1000000);
  y_hat = integrate_ode_rk45(logisticgrowth, y0, t0, ts, theta, x_r, x_i);
  for (t in 1:T) {
    for (i in 1:nReplicates) {
      z[t,i] ~ normal(y_hat[t,i], sigma[i]);
    }
  }
}

//
generated quantities{
  real y_pred[T,nReplicates];
  real z_pred[T,nReplicates];
  y_pred = integrate_ode_rk45(logisticgrowth, y0, t0, ts, theta, x_r, x_i );
  for (t in 1:T) {
    for(i in 1:nReplicates){
      z_pred[t,i] = y_pred[t,i] + normal_rng(0,sigma[i]);
    }
  }
}

#include <cmath>

#define __STDC_CONSTANT_MACROS
extern "C" {
#include <libavutil/tx.h>
}

#include "spek-fft.h"

class FFTPlanImpl : public FFTPlan
{
public:
    FFTPlanImpl(int nbits);
    ~FFTPlanImpl() override;

    void execute() override;

private:
    AVTXContext *cx;
    av_tx_fn tx;
    // R2C output: (n / 2 + 1) complex values, interleaved re/im.
    float *tx_output;
};

std::unique_ptr<FFTPlan> FFT::create(int nbits)
{
    return std::unique_ptr<FFTPlan>(new FFTPlanImpl(nbits));
}

FFTPlanImpl::FFTPlanImpl(int nbits) : FFTPlan(nbits), cx(nullptr), tx(nullptr)
{
    const float scale = 1.0f;
    av_tx_init(&this->cx, &this->tx, AV_TX_FLOAT_RDFT, 0, 1 << nbits, &scale, 0);
    this->tx_output = (float*) av_malloc(sizeof(float) * (this->get_input_size() + 2));
}

FFTPlanImpl::~FFTPlanImpl()
{
    av_tx_uninit(&this->cx);
    av_freep(&this->tx_output);
}

void FFTPlanImpl::execute()
{
    this->tx(this->cx, this->tx_output, this->get_input(), sizeof(float));

    // Calculate magnitudes.
    int n = this->get_input_size();
    float n2 = n * n;
    for (int i = 0; i <= n / 2; i++) {
        float re = this->tx_output[i * 2];
        float im = this->tx_output[i * 2 + 1];
        this->set_output(i, 10.0f * log10f((re * re + im * im) / n2));
    }
}
